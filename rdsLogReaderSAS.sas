%macro rdsLogReaderSAS
  (  method
   , project=DEFAULT
   , job=DEFAULT
   , logFileName=
   , logData=rdsLog
   , stepData=rdsStep
   , ioData=rdsIO
   , lineData=rdsLine
   , errorData=rdsError
   , dbLibName=
  );

  /**
  * === rdsLogReader ===================================================
  *
  * rdsLogReader - A macro to read and analyze SAS(r) logs.
  *
  * Note: SAS is a registered trademark of SAS Institute Inc.
  *   (www.sas.com)
  *
  * === License
  *
  *  Copyright (c) 2005 KYBEIDOS GmbH (www.kybeidos.de)
  *
  *  This program is free software; you can redistribute it and/or
  *  modify it under the terms of the GNU General Public License as
  *  published by the Free Software Foundation; either version 2 of the
  *  License, or (at your option) any later version.
  *
  *  This program is distributed in the hope that it will be useful, but
  *  WITHOUT ANY WARRANTY; without even the implied warranty of
  *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  *  General Public License for more details.
  *
  *  The GNU General Public License is published by the Free Software
  *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  *  USA at:
  *
  *     http://www.opensource.org/licenses/gpl-license.php
  *
  *  ===
  *
  *  This macro is part of the Yalan library to analyze SAS(r) logs.
  *
  *  Yalan - Yet another log analyzer.
  *
  *  Note: You will find more information on Yalan at www.redscope.org.
  *
  * === Changes
  *
  * 2004-06-24  sfrenzel(at)kybeidos.de
  *
  *   Initial version (named kybLogReader)
  *
  * 2004-12-27  sfrenzel(at)kybeidos.de
  *
  *   Renamed to rdsLogReader
  *
  * 2005-01-24  sfrenzel(at)kybeidos.de
  *
  *   Formatting for OS390 (72 cols max)
  *
  * 2005-01-24  sfrenzel(at)kybeidos.de
  *
  *   Method historize
  *
  * 2005-02-20  sfrenzel(at)kybeidos.de
  *
  *   Separated identification and parsing of log lines.
  *   Included handling of error messages.
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  *
  * 2015-04-28  sfrenzel@kybeidos.de
  *
  *   Change digest implementation to MD5
  *
  * 2015-07-20 idoig@kybeidos.de
  *     add pattern_title = prxparse("/SAS System \d\d:/") to allow differentiation
  *       in rdsLRSASMessages between " SAS System  " & " SAS System hh:"  
  *
  * === Todos
  *
  * Complete the set of log messages recognised on various platforms and
  * SAS(r) versions.
  */

  %local _logData inputData outputData libData;

  %local umn _digest _date _time _project _job _logId _logIdDelete;
  %let umn = rdsy01;
  %let _date = .;
  %let _time = .;

  %local _i _to _LDBLibname;
  %let _LDBLibname = %rdsYalan(getLDBLibname);

  /**
  * Method: readLog
  */
  %if (%lowcase (&method.) = %lowcase (readLog)) %then %do;

    ** Get the name of a temporary data set containing the log;
    %let _logData = %rdsDataSet (getUniqueDataSetName, prefix=log);

    ** Read the log file;
    data &_logData.;

      ** Read lines from log, trim special characters ('.' and ',');
      lineNo = _n_;
      infile "&logFileName." end=_done length=_rl;
      input line $varying256. _rl;

      _c = substr (left (reverse (line)), 1, 1);
      if (_c in (',', '.')) then do;
        line = substr (line, 1, length(trim(line))-1);
      end;
      drop _:;

      /*
       * Calculate a digest of the log file
       *
       * What is a digest? In short: A digest (in case of a file) is a
       * sort of a finger print of a file. Files with the same digest do
       * most propably have the same content. Files with different digests
       * do certainly have different contents.
       */
      attrib
        logDigest
          format = $32.
          label = 'Digest of Log'
      ;
      retain logDigest '';

      if (line not= '') then
        logDigest = put (md5 (logDigest !! line), hex32.);
      /* Implementation until 2015-04-24: */
      /* Fixme: Remove after successful testing of new Implementation */
      /*
      if (line not= '') then do;
        logDigest = 
          bxor
          (  logDigest
           , input
             (  compress
                  (  reverse(soundex('x'!!line!!'x'))
                   , 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
              , ?? 8.
          )  );
      end;
      */

      if (_done) then call symput ("_digest", logDigest);

    run;

    ** Select log lines to evaluate;
    proc sql noprint;
      create table &_logData. as select
      logDigest,
      line,
      lineNo,
      case
        %rdsLRSASMessages (identifyLines)
        %rdsLRSASJCL (identifyLines)
        %rdsLRSASErrors (identifyLines)
        else ''
      end
        as exp
      from &_logData.
      /* Digest should be read from last line - 
         where exp may by null */
      /* where calculated exp is not null */
      ;
    quit;

    /*
     * Get names of temporary data sets to contain information extracted
     * from the log
     */
    %let inputData = %rdsDataSet (getUniqueDataSetName, prefix=input);
    %let outputData = %rdsDataSet (getUniqueDataSetName, prefix=output);
    %let libData = %rdsDataSet (getUniqueDataSetName, prefix=lib);

    ** Extract information from selected log lines;
	*proc contents data=&_logData.; run; /* FRL */
	proc print data=&_logData.; run; /* FRL */
    data
      &logData.    (keep=log: project job date time)
      &stepData.   (keep=logId step: lineNo index=(step))
      &lineData.   (keep=logId step line: project job date time)
      &inputData.  (keep=logId step input:)
      &outputData. (keep=logId step output:)
      &libData.    (keep=logId step lib:
                    index=(StepTypeName=(step libType libName))
                   )
      &errorData   (keep=logId step lineNo error:)
    ;

      if _n_=1 then do;
        pattern_title=prxparse("/SAS System \d\d:/");
        retain pattern_title ;
      end; 
      attrib
        logId
          format = 8.
          label = 'Sequence Number of Log'
        logFileName
          format = $256.
          label = 'Name of Log File'
        logDatetime
          format = datetime18.
          label = 'Timestamp of Log'
        logDigest
          format = $32.
          label = 'Digest of Log'
        project
          format=$20.
          label = 'Name of Project'
        job
          format = $20.
          label = 'Name of Job'
        %rdsLRSASMessages (declare)
        %rdsLRSASJCL (declare)
        %rdsLRSASErrors (declare)
      ;
      ** Avoid "uninitialized" messages;
      logId = -1;
      inputLibFileName = ' ';
      outputLibFileName = ' ';
      logFileName = "&logFileName.";
      project = "&project.";
      job = "&job.";
      retain _p 0 inputNo 0 outputNo 0 date 0 time 0;
      _p+1;
      set &_logData. point=_p nobs=_n;
      retain step 1;

	  *put line=; /* FRL */

      /**/
		retain _SASTags "data proc substr print sort by shr keep";
		retain _Delimiters " `´'""#*+~,-;:<>|=)(/$§!";
		length _c $ 1;
		if exp = '' and line ^= '' then do;
			length _tag $ 32;
			_j=1;
			do while (_j <= length (trim (line)));
				_tag = '';
				_c = substr (line, _j, 1); 
				do while (index (_Delimiters, _c) = 0);
					_tag = left (trim (left (_tag)) !! lowcase (_c));
					_j+1;
					if _j > length (trim (line)) then leave;
					_c = substr (line, _j, 1);
				end;
				if verify (trim (_tag), "abcdefghijklmnopqrstuvwxyz_.%&0123456789 ") = 0 and
				    index ('0123456789', substr (left(_tag), 1, 1)) = 0 and
					indexw (lineTags, trim (_tag)) = 0 and
					indexw (_SASTags, trim(_tag)) = 0 then
					lineTags = trim (lineTags) !! ' ' !! _tag;
				if (_c = '=' and count(line, "=") <= 1) then do;
					if index (lowcase (line), "rename") then lineTags = trim (lineTags) !! ' >';
					else lineTags = trim (lineTags) !! ' <';
				end;
				_j+1;
			end;
			if lineTags ^= '' then link writeLineData;
		end;
		link writeLineData;
      /**/
  
      if exp not= '' then do;
        ** Evaluate lines of sas log;
        select (exp);
          %rdsLRSASMessages (parseLines)
          %rdsLRSASJCL (parseLines)
          %rdsLRSASErrors (parseLines)
          otherwise;
        end;
      end;
	  
      if _p >= _n then do;
        link writeLogData;
        stop;
      end;
    return;
    writeLogData:
      output &logData.;
    return;
    writeStepData:
      output &stepData.;
      *stepVars = '';
      inputNo = 0;
      outputNo = 0;
      step+1;
    return;
    writeLineData:
      output &lineData.;
    return;
    writeInputData:
      inputNo + 1;
      output &inputData.;
    return;
    writeOutputData:
      outputNo + 1;
      output &outputData.;
    return;
    writeErrorData:
      output &errorData.;
    return;
    run;
	proc print data=&stepData.;run;

    ** Done with the data set containing log lines;
    %rdsDataSet (drop, data=&_logData.);

    /*
     * For input and output data sources: Lookup information about the
     * input/output libraries.
     * Allocation of input/output libraries may occur in an earlier
     * step than read/write operations. We therefor have to step backwards
     * through the log to find the matching allocation
     */
    %macro _rdsLookupLib (io);
      data &&&io.putData.;

        ** Define variables from library data set;
        if 0 then set &libData.;

        /*
         * The variable to hold the physical library name is already
         * defined. We will rewrite the data set.
         */
        modify &&&io.putData.;

        ** Prepare lookup;
        libFileName='';
        if (&io.putName not= '') then do;
          libType = &io.putType;
          if (&io.putType = 'SEQ') then libName = &io.putName;
          else if (&io.putType = 'SAS') then
            libName = scan (&io.putName, 1);
          ** Call lookup routine;
          if (libName not= 'WORK') then link lookupLib;
          &io.putLibFileName = libFileName;
        end;
        drop lib:;
        _error_=0;
      return;

      ** Lookup library allocation stepping back through the sas log;
      lookupLib:
        _step=step;
        do step=step to 1 by -1 while (libFileName='');
          set &libData. key=StepTypeName / unique;
        end;
        step=_step;
        drop _step;
      return;
      run;
    %mend _rdsLookupLib;
    %_rdsLookupLib (in);
    %_rdsLookupLib (out);

    /*
     * Merge information about input data and output data for the steps
     * to have these informations side by side.
     */
    data &ioData.;
      merge
        &inputData. (rename=(inputNo=no))
        &outputData. (rename=(outputNo=no))
      ;
      by step no;
      label no = 'Number of data source within step';
      /*
    data &ioData.;
      merge &stepData. &ioData.;
      by step;
      */
    run;

    %rdsDataSet (drop, data=&inputData.);
    %rdsDataSet (drop, data=&outputData.);
    %rdsDataSet (drop, data=&libData.);

    %put Log file &logFileName. read successfully with Digest: &_digest.;

  %end; %* method: readLog;

  /**
  * Method: historize
  */
  %if (%lowcase (&method.) = %lowcase (historize)) %then %do;

    %if %sysfunc(exist(&_LDBLibname..log)) = 0 %then %do;
      data &_LDBLibname..log; stop; set &logData.; run;
      data &_LDBLibname..step; stop; set &stepData.; run;
      data &_LDBLibname..line; stop; set &lineData.; run;
      data &_LDBLibname..io; stop; set &ioData.; run;
      data &_LDBLibname..error; stop; set &errorData.; run;
    %end;

    ** Delete log information from log database if the same log
      is read twice;
    data _null_;
      set &logData. (keep=project job date time logDigest);
      call symput ('_project', trim(project));
      call symput ('_job'    , trim(job));
      call symput ('_date'   , put (date, 12.));
      call symput ('_time'   , put (time, 12.));
      call symput ('_digest' , logDigest);
      stop;
    run;
    %put _digest=&_digest.;
    %let _logId = 1;
    %let _logIdDelete = -1;
    proc sql noprint;
      ** Determine unique log id, insert data into log table;
      select logId into :_logIdDelete from &_LDBLibname..log
       where project = "&_project." and job = "&_job." and
             date = &_date. and time = &_time. and logDigest="&_digest.";
      delete from &_LDBLibname..log where logId = &_logIdDelete.;
      select max(logId)+1 into :_logId from &_LDBLibname..log;
    %if &_logId. le 0 %then %let _logId = 1;
      insert into &_LDBLibname..log
          (logId, project, job, date, time, logDigest, logFileName,
           logDatetime)
        select
          &_logId., project, job, date, time, logDigest, logFileName,
           logDatetime
        from &logData.;
      ** Delete data from dependend tables;
      delete from &_LDBLibname..step where logId = &_logIdDelete.;
      delete from &_LDBLibname..line where logId = &_logIdDelete.;
      delete from &_LDBLibname..io where logId = &_logIdDelete.;
      delete from &_LDBLibname..error where logId = &_logIdDelete.;
    update &stepData. set logId = &_logId.;
    update &lineData. set logId = &_logId.;
    update &ioData. set logId = &_logId.;
    update &errorData. set logId = &_logId.;
    quit;

    ** Append data to dependent tables;
    proc append base=&_LDBLibname..step data=&stepData.;
    proc append base=&_LDBLibname..line data=&lineData.;
    proc append base=&_LDBLibname..io data=&ioData.;
    proc append base=&_LDBLibname..error data=&errorData.;
    run;

  %end; %* method: historize;

%mend rdsLogReaderSAS;
