%macro rdsLogFilePoller (method);

  /**
  * === rdsLogFilePoller ===============================================
  *
  * rdsLogFilePoller - A SAS(r) macro which polls for new sas logs
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
  * === Changes
  *
  * 2005-03-30  sfrenzel@kybeidos.de
  *
  *   Initial version
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  */

  %global
    RDSLOGFILEPOLLER_CommandData
    RDSLOGFILEPOLLER_Terminate
  ;

  %local _LDBLibname;
  %let _LDBLibname = %rdsYalan (getLDBLibname);

  %local logFile logFile0 _i _tempFile _lastRun _CommandFileChanged;

  /**
  * Initialize internal variables
  */
  %if %length (&RDSLOGFILEPOLLER_CommandData.) = 0 %then %do;
    %let RDSLOGFILEPOLLER_CommandData = %rdsDataSet (getUniqueDataSetName, prefix=cds);
    data &RDSLOGFILEPOLLER_CommandData. (index=(line));
      stop;
      length line $ 256.;
   line='';
    run;
  %end;

  /**
  * Method: start
  */
  %if (%lowcase (&method.) = %lowcase (start)) %then %do;

    %let RDSLOGFILEPOLLER_Terminate = false;

    %do %until (&RDSLOGFILEPOLLER_Terminate. = true);

    %let _lastRun = %sysfunc(datetime());
    %let logFile = %rdsDataSet(getUniqueDataSetName, prefix=lf);
    %let logFile0 = %rdsDataSet(getUniqueDataSetName, prefix=lf0);

    %do _i=1 %to %rdsYalan(getLogFileNameCount);

        %rdsFileFinder
        (  findFile
         , directoryName = %rdsYalan (getLogFileDirectory, &_i.)
         , pattern = %rdsYalan (getLogFilePattern, &_i.)
         , outFile = &logFile0.
        );
        proc append base = &logFile. data=&logFile0.;
        run;

    %end;

    %rdsDataSet(drop, data=&logFile0.);

    %if %sysfunc(exist(&_LDBLibname..logFile)) = 0 %then %do;
      data &_LDBLibname..logFile;
        stop;
        set &logFile.;
        format
          timeFound datetime19.2
          existed   1.;
      run;
    %end;

    %let _tempFile = %rdsFile (getUniqueFileName, prefix=temp);
    filename &_tempFile. temp;
    proc sort data=&logFile.;
      by pathName;
    proc sort data=&_LDBLibname..logFile;
      by pathName;
    data &_LDBLibname..logFile;
      merge &_LDBLibname..logFile (in = known) &logFile. (in = current);
      by pathName;
      length _stmt $ 300;
      file &_tempFile. lrecl=300;
      if (not existed and current) then do;
        timeFound = datetime();
        ** Invoke method 'readLog'. This will create 4 data set in the work library, containing
           information about: The log, the steps, data sets having been read and written, errors;
        _stmt = '%rdsLogReaderSAS (readLog, logFileName =' !! trim (pathName) !! ');'; put _stmt;
        ** Write informations from the work library to the log database;
        _stmt = '%rdsLogReaderSAS (historize);'; put _stmt;
        drop _stmt;
      end;
      existed = current;
    run;
    %inc &_tempFile.;
    filename &_tempFile. clear;

    %rdsDataSet(drop, data=&logFile.);

    data _null_;
      t = ((%rdsYalan (getPollingInterval) - (datetime() - &_lastRun.))*1000);
      put t=;
      call sleep(t);
    run;

    %if (%length (%rdsYalan (getCommandFile)) ne 0) %then %do;
      %let _CommandFileChanged = 0;
      data &RDSLOGFILEPOLLER_CommandData. (index=(line));
        infile "%rdsYalan (getCommandFile)" lrecl=256 pad;
        input line $256.;
        set &RDSLOGFILEPOLLER_CommandData. key=line;
        if (_iorc_ not= 0) then do;
          call symput ('_CommandFileChanged', '1');
          _error_ = 0;
          stop;
        end;
      run;
      %if (&_CommandFileChanged. = 1) %then %do;
        %inc "%rdsYalan (getCommandFile)";
      %end;
    %end; %* There is a command file;

    %end; %* Until RDSLOGFILEPOLLER_Terminate = true;

  %end;

  /**
  * Method: stop
  */
  %if (%lowcase (&method.) = %lowcase (stop)) %then %do;

    %let RDSLOGFILEPOLLER_Terminate = true;

  %end;

%mend;
