%macro rdsFileFinder
  (  method
   , directoryName=
   , pattern=
   , depth=1
   , ddTemp=
   , outFile=
  );

  /**
  * === rdsFileFinder =================================================
  *
  * rdsFileName - A SAS(r) macro to search for external files.
  *
  * Note: SAS is a registered trademark of SAS Institute Inc.
  *  (www.sas.com)
  *
  * === License
  *
  * Copyright (c) 2005 KYBEIDOS GmbH (www.kybeidos.de)
  *
  * This program is free software; you can redistribute it and/or
  * modify it under the terms of the GNU General Public License as
  * published by the Free Software Foundation; either version 2 of the
  * License, or (at your option) any later version.
  *
  * This program is distributed in the hope that it will be useful, but
  * WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  * General Public License for more details.
  *
  * The GNU General Public License is published by the Free Software
  * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  * USA at:
  *
  *    http://www.opensource.org/licenses/gpl-license.php
  *
  * ===
  *
  * This macro is part of the Yalan library to analyze SAS(r) logs.
  *
  * Yalan - Yet another log analyzer.
  *
  * Note: You will find more information on Yalan at www.redscope.org.
  *
  * Method: findFile
  *
  * This method searches for files of a given pattern (parameter:
  * pattern) in the directory named in parameter DirectoryName.
  * The files found will be returned in the data set named in parameter
  * outFile.
  *
  * === Changes
  *
  * 2004-06-24  sfrenzel@kybeidos.de
  *
  *   Initial version
  *
  * 2005-09-30  sfrenzel@kybeidos.de
  *
  *   Support for MVS (IDCAMS)
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  */

  %local rdsAt rdsTempFile;
  %let rdsAt = @;
  %let rdsTempFile = %rdsFile (getUniqueFilename);

  /**
  * Method: findFile
  */
  %if (%lowcase (&method.) = %lowcase (findFile)) %then %do;

    %if (&sysscp. = OS) %then %do;

      data _null_;
        call symput ('rdsAt', '7C'x);
      run;

      %let directoryName = %upcase (&directoryName.);
      %let pattern       = %upcase (&pattern.);

      /* Temporary DS to pass commands to IDCAMS */
      filename sysin
         '&sysin' space=(trk,(1,1))
         unit=sysda recfm=fb lrecl=80 blksize=23440;

      /* Temporary DS to capture output from IDCAMS */
      filename sysprint
         '&sysprint' space=(trk,(10,10)) unit=sysda
          recfm=fba lrecl=133 blksize=23408;

      /* Write IDCAMS commands */
      data _null_;
        file sysin;
        PUT " LISTCAT LVL(%upcase(&directoryName.))";
      run;

      /* Call IDCAMS */
      proc idcams;
      run;

      /* Parse IDCAMS-Output */
      data &outFile.;
        infile sysprint pad;
        length directoryName pathName fileName $ 42;
        retain directoryName "&directoryName.";
        input &rdsAt. 2 _rectype $char8. &rdsAt.;
        if _rectype = "NONVSAM " then do;
          input &rdsAt. 18 pathName $char42. /;
          fileName = substr (pathName, length(trim(directoryName))+2);
          /* Test if file can be read. (It may be locked be a running job.) */
          _rc = filename ("&rdsTempFile.", pathName);
          _did = fopen ("&rdsTempFile.", 'I');
          if (_did) then do;
            output;
            _did = fclose (_did+0);
          end;
          else do;
            put;
            put "Note: " pathName "seems to be locked. It will be skipped.";
            put;
          end;
          _rc = filename ("&rdsTempFile.");
        end;
        drop _rectype _rc _did;
      run;

    %end; %* SYSSCP = OS;

    %else %do;

      %local ddFile ddDirectory isExternalCall;
      %let ddFile = %rdsFile (getUniqueFilename, prefix = f);
      %let ddDirectory = %rdsFile (getUniqueFilename, prefix = d);

      %if %length(&ddTemp.) = 0 %then %do;
        %let isExternalCall = true;
        data _null_;
          if (not fileexist("%trim(&directoryName.)")) then
            put "ERROR: Directory &directoryName. does not exist.";
          call symput ('pattern', translate ("&pattern.", '%_', '*?'));
        run;
        %let ddTemp = %rdsFile (getUniqueFilename, prefix = t);
        filename &ddTemp. temp;
        %* Write empty record, in case no file will be found;
        %let tempFile = %sysfunc(fopen (&ddTemp., a)); %*put &depth. ------ Open temporary file (initialization): &tempFile.;
        %let rc = %qsysfunc (fput (&tempFile., _)); %*put &depth. ------ Put to temporary file (initialization): &rc.;
        %let rc = %sysfunc(fwrite (&tempFile.)); %*put &depth. ------ Write to temporary file (initialization): &rc.;
        %let tempFile = %sysfunc(fclose (&tempFile.)); %*put &depth. ------ Close temporary file (initialization): &tempFile.;
      %end;
      %else %do;
        %let isExternalCall = false;
      %end;

      %local directory i fileName pathName file;

      %*put &depth. -- directoryName = &directoryName.;
      %let rc = %sysfunc (filename (ddDirectory, &directoryName.)); %*put &depth. ---- Allocation of directory: &rc.;
      %let directory = %sysfunc (dopen (&ddDirectory.)); %*put &depth. ---- Open directory: &directory.;
      %if (&directory. ne 0) %then %do i=1 %to %sysfunc (dnum (&directory.));
        %let fileName = %sysfunc (dread (&directory., &i.)); %*put &depth. ---- FileName: &fileName.;
        %let pathName = &directoryName./&fileName.; %*put &depth. ---- PathName: &pathName.;
        %let rc = %sysfunc (filename (ddFile, &pathName.)); %*put &depth. ------ Allocation of file: &rc.;
        %let file = %sysfunc(fopen (&ddFile., i)); %*put &depth. ------ Open file: &file.;
        %if &file. ne 0 %then %do;
          %*put &depth. ------ File!;
          %let file = %sysfunc(fclose (&file.)); %*put &depth. ------ Close file: &file.;
          %let rc = %sysfunc (filename (ddFile)); %*put &depth. ------ Deallocation of file: &rc.;
          %* Write file to temporary file;
          %let tempFile = %sysfunc(fopen (&ddTemp., a)); %*put &depth. ------ Open temporary file: &tempFile.;
          %let rc = %qsysfunc (fput (&tempFile., &directoryName.)); %*put &depth. ------ Put to temporary file: &rc.;
          %let rc = %sysfunc(fwrite (&tempFile.)); %*put &depth. ------ Write to temporary file: &rc.;
          %let rc = %qsysfunc (fput (&tempFile., &fileName.));
          %let rc = %sysfunc(fwrite (&tempFile.));
          %let rc = %qsysfunc (fput (&tempFile., &pathName.));
          %let rc = %sysfunc(fwrite (&tempFile.));
          %let tempFile = %sysfunc(fclose (&tempFile.)); %*put &depth. ------ Close temporary file: &tempFile.;
        %end;
        %else %do;
          %*put &depth. ------ Directory!;
          %let rc = %sysfunc (filename (ddFile)); %*put &depth. ------ Deallocation of file: &rc.;
          %* Call macro recursively;
          %rdsFileFinder (findFile, directoryName = &pathName., depth = %eval (&depth.+1), ddTemp = &ddTemp.);
        %end;
      %end; %* All files of current directory;
      %else %do;
        %put;
        %put Note: &directoryName. is either not a directory or it is a file;
        %put which is currently locked. It will be skipped.;
        %put;
      %end;
      %let directory = %sysfunc(dclose (&directory.)); %*put &depth. -- Close directory: &directory.;
      %let rc = %sysfunc (filename (ddDirectory)); %*put &depth. -- Deallocation of directory: &rc.;

      %if (&isExternalCall = true) %then %do;
        data &outFile.;
          infile &ddTemp. firstobs=2;
          input; directoryName = _infile_;
          input; fileName = _infile_;
          input; pathName = _infile_;
        run;
        filename &ddTemp.;
        proc sql;
          delete from &outFile. where fileName not like "&pattern.";
        quit;
      %end;

    %end; %* SYSSCP not= OS;

  %end; %* Method: findFile;

  /**
  * Method: testAll
  */
  %if (%lowcase (&method.) = %lowcase (testAll)) %then %do;
    %let logFiles=%rdsDataSet (getUniqueDataSet, prefix=lf);
    %* TODO: Take a directory that exists on every machine;
    proc print noobs data=&logFiles.;
    run;
  %end;

%mend rdsFileFinder;
