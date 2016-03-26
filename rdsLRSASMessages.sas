%macro rdsLRSASMessages (method);

  /**
  *  === rdsLogReader ===================================================
  *
  *  rdsLRSASMessages - A macro to identify and parse sas(r) log messages
  *
  *  Note: SAS is a registered trademark of SAS Institute Inc.
  *    (www.sas.com)
  *
  *  === License
  *
  *   Copyright (c) 2005 KYBEIDOS GmbH (www.kybeidos.de)
  *
  *   This program is free software; you can redistribute it and/or
  *   modify it under the terms of the GNU General Public License as
  *   published by the Free Software Foundation; either version 2 of the
  *   License, or (at your option) any later version.
  *
  *   This program is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  *   General Public License for more details.
  *
  *   The GNU General Public License is published by the Free Software
  *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  *   USA at:
  *
  *      http://www.opensource.org/licenses/gpl-license.php
  *
  *   ===
  *
  *   This macro is part of the Yalan library to analyze SAS(r) logs.
  *
  *   Yalan - Yet another log analyzer.
  *
  *   Note: You will find more information on Yalan at www.redscope.org.
  *
  *  === Changes
  *
  *  2005-02-20  sfrenzel(at)kybeidos.de
  *
  *    Initial version.
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  *
  * 2015-04-29  sfrenzel@kybeidos.de
  *
  *   Interpretation of Libname Engine
  *   Apply "upcase()" to inputName, outputName, libName
  *
  * 2015-07-20 idoig@kybeidos.de 
  *   Change LOG_PAGE_HEADER search to "% SAS System %" from
  *     % The SAS System % - some logs in German with Das SAS System!  
  *
  * 2015-07-20 idoig@kybeidos.de
  *     use pattern_title from rdsLogReader to allow differentiation
  *       in rdsLRSASMessages between " SAS System  " & " SAS System hh:"  
  *       logDatetime should now always be filled.
  */

  /**
  * Apply COMPESS and UPCASE to dataset names
  */
  %macro rdsLRSASMessagesCPUP (exp);
    compress (upcase (translate (&exp., '/', '\')), '''"')
  %mend;

  /**
  * Method: declare
  */
  %if (%lowcase (&method.) = %lowcase (declare)) %then %do;

    step
      format=5.
      label='Number of step'
    stepName
      format=$8.
      label='Data step or procedure name'
	  /*
    stepVars
      format=$2000.
      label='Variables used in step'
	  */
    stepCPUTime
      format=commax12.2
      label='CPU time of step'
    stepRealTime
      format=commax12.2
      label='Elapsed time of step'
    stepTaskMemory
      format=12.
      label='Memory usage of step'
	  /*
    lineStep
      format=5.
      label='Number of step'
	  */
    lineTags
      format=$2000.
      label='Tags of log line'
    lineNo
      format=8.
      label='Line number'
    line
      format=$2000.
      label='Text of log line'
    inputNo
      format=3.
      label='Number of input data source within step'
    inputType
      format=$3.
      label='Type of input data source'
    inputName
      format=$80.
      label='Logical name of input data source'
    inputLibFileName
      format=$256.
      label='Physical name of input file or library'
    inputObs
      format=12.
      label='Number of observations read from input data source'
    outputNo
      format=3.
      label='Number of output data source within step'
    outputType
      format=$3.
      label='Type of output data source'
    outputName
      format=$80.
      label='Logical name of output data source'
    outputLibFileName
      format=$256.
      label='Physical name of output file or library'
    outputObs
      format=12.
      label='Number of observations written to output data source'
    outputVars
      format=12.
      label='Number of variables written to output data source'
    libType
      format=$3.
      label='Type of library'
    libEngine
      format=$32.
      label='Library engine'
    libName
      format=$32.
      label='Logical name of library'
    libFileName
      format=$256.
      label='Physical name of library'

  %end;

  /**
  * Method: identifyLines
  */
  %if (%lowcase (&method.) = %lowcase (identifyLines)) %then %do;

    when
      (line like '%NOTE: DATA statement used%')
      then 'DATA_USED'
    when
      (line like '%NOTE: The DATA statement used%CPU%')
      then 'THE_DATA_USED_CPU'
    when
      (line like '%NOTE:%DATA statement used % resources:%')
      then 'DATA_USED_RESOURCES'
    when
      (line like '%NOTE: PROCEDURE % used%')
      then 'PROCEDURE_USED'
    when
      (line like '%NOTE: PROZEDUR % used%')
      then 'PROCEDURE_USED'
    when
      (line like '%NOTE: The PROCEDURE % used%CPU%')
      then 'THE_PROCEDURE_USED_CPU'
    when
      (line like '%NOTE:%PROCEDURE % used % resources:%')
      then 'PROCEDURE_USED_RESOURCES'
    when
      (line like
       '%CPU%time -%')
      then 'FS_CPU_TIME'
    when
      (line like
       '%Elapsed time -%')
      then 'FS_ELAPSED_TIME'
    when
      (line like
       '%Task%memory -%')
      then 'FS_TASK_MEMORY'
    when
      (line like
       '%cpu time%')
      then 'CPU_TIME'
    when
      (line like
       '%real time%')
      then 'REAL_TIME'
    when
      (line like
       '%NOTE: There were % observations read from the data set %')
      then 'READ_FROM_DATA_SET'
    when
      (line like '%NOTE: % records were read from the infile "%"')
      then 'READ_FROM_FILE_PN'
    when
      (line like '%NOTE: A total of % records were read from the infile %')
      then 'READ_FROM_FILE1'
    when
      (line like '%NOTE: % records were read from the infile %')
      then 'READ_FROM_FILE2'
    when
      (line like
       '%NOTE: The data set % has % observations and % variables%')
      then 'WRITTEN_TO_DATA_SET'
    when
      (line like '%NOTE:%row%inserted into%')
      then 'ROWS_INSERTED'
    when
      (line like '%NOTE:%row%updated in%')
      then 'ROWS_UPDATED'
    when
      (line like '%NOTE:%row%deleted from%')
      then 'ROWS_DELETED'
    when
      (line like '%NOTE: The file library % is:%')
      then 'FILE_LIB_IS'
    when
      (line like '%NOTE: The %file % is:%')
      then 'FILE_IS'
    when
      (line like '%Dsname=%')
      then 'DSNAME'
    when
      (line like '%Filename=%')
      then 'FILENAME'
    when
      (line like '%SESSION=%')
      then 'SESSION'
    when
      (line like '%Dateiname=%')
      then 'DATEINAME'
    when
      (line like
       '%NOTE: A total of % records were written to the file library %'
      ) then 'WRITTEN_TO_FILE_LIB'
    when
      (line like '%NOTE: % records were written to the file %')
      then 'WRITTEN_TO_FILE'
    when
      (line like '%NOTE: Table % created, with % rows and % columns%')
      then 'TABLE_CREATED'
    when
      (line like
       '%NOTE: Libref % was successfully assigned as follows:%')
      then 'LIBREF_ASSIGNED'
    when
      (line like '%Physical Name: %')
      then 'PHYSICAL_NAME'
    when
      (line like '%Engine: %')
      then 'LIBNAME_ENGINE'
    when
      (line like '% SAS System %')
      then 'LOG_PAGE_HEADER'

  %end;

  /**
  * Method: parseLines
  */
  %if (%lowcase (&method.) = %lowcase (parseLines)) %then %do;

    when ('DATA_USED') do;
      ** NOTE: DATA statement used:%;
      %macro _readST;
        ** Currently only 2 lines of the stats output are being inter-
           preted. Increase lines read when parsing additional lines;
        do _i=1 to 2;
          _p+1;
          set &_logData. point=_p nobs=_n;
          select (exp);
            when ('CPU_TIME') do;
              ** %cpu time%;
              stepCPUTime = input (left(scan(line,3,' ')), 12.2);
            end;
            when ('REAL_TIME') do;
              ** %real time%;
              stepRealTime = input (left(scan(line,3,' ')), 12.2);
            end;
            otherwise;
          end;
        end;
        _p+(-2); ** see above;
      %mend;
      %_readST;
      stepName = 'DATA';
      link writeStepData;
    end;
    when ('THE_DATA_USED_CPU') do;
      ** NOTE: The DATA statement used%CPU%;
      stepCPUTime =
        input (scan (line,6,' :'), best.);
      stepTaskMemory =
        input (compress (scan (line,10,' :'),'MK.'),best.);
      stepName = 'DATA';
      link writeStepData;
    end;
    when ('DATA_USED_RESOURCES') do;
      ** NOTE: The DATA statement used the following resources:;
      stepName = 'DATA';
      %macro _readFS;
        ** Currently only 3 lines of the FS output are being inter-
           preted. Increase lines read when parsing additional lines;
        do _i=1 to 3;
          _p+1;
          set &_logData. point=_p nobs=_n;
          select (exp);
            when ('FS_CPU_TIME') do;
              ** %CPU     time -%;
              stepCPUTime = input (left(scan(line,2,'-')), time12.2);
            end;
            when ('FS_ELAPSED_TIME') do;
              ** Elapsed time -%;
              stepRealTime = input (left(scan(line,2,'-')), time12.2);
            end;
            when ('FS_TASK_MEMORY') do;
              ** Task  Memory -%;
              stepTaskMemory =
                input(compress(scan (line,2,'-('),'MK'),best.);
            end;
            otherwise;
          end;
        end;
        _p+(-3); ** see above;
      %mend;
      %_readFS;
      link writeStepData;
    end;
    when ('PROCEDURE_USED') do;
      ** NOTE: PROCEDURE % used:%;
      stepName = scan (line, 3, ' :');
      %_readST;
      link writeStepData;
    end;
    when ('THE_PROCEDURE_USED_CPU') do;
      ** NOTE: The PROCEDURE % used%CPU%;
      stepCPUTime =
        input (scan (line,6,' :'), best.);
      stepTaskMemory =
        input (compress (scan (line,10,' :'),'MK.'),best.);
      stepName = scan (line, 4, ' :');
      link writeStepData;
    end;
    when ('PROCEDURE_USED_RESOURCES') do;
      ** NOTE: The Procedure % used the following resources:;
      stepName = scan (line, 4, ' :');
      %_readFS;
      link writeStepData;
    end;
    when ('READ_FROM_DATA_SET') do;
      ** NOTE: There were % observations read from the data set %.;
      inputType= 'SAS';
      inputName = upcase (scan (line, 11, ' :'));
      inputObs = input (scan (line, 4), best.);
      link writeInputData;
    end;
	/*
	* Todo: The infile messages parsed in the blow branches sometimes
	* span over more than one line, i.e.:
      NOTE: 488 records were read from the infile "p:\5091\GRP09\F-FMBA\GMIS 
      Plausibilisierung\2_OUTPUT\extass_dfo_up.csv".
    */
    when ('READ_FROM_FILE_PN') do;
      ** NOTE: % records were read from the infile "%".;
      inputType= 'SEQ';
      inputName= '';
      inputLibFileName = 
         %rdsLRSASMessagesCPUP (%str (scan (line, 2, '"')));
      inputObs = input (scan (line, 2, ' :'''), best.);
      link writeInputData;
    end;
    when ('READ_FROM_FILE1') do;
      ** NOTE: A total of % records were read from the infile %.;
      inputType= 'SEQ';
      inputName = upcase (scan (line, 13, ' :'''));
      inputObs = input (scan (line, 5, ' :'''), best.);
      link writeInputData;
    end;
    when ('READ_FROM_FILE2') do;
      ** NOTE: % records were read from the infile %.;
      inputType= 'SEQ';
      inputName = upcase (scan (line, 9, ' :'''));
      inputObs = input (scan (line, 2, ' :'''), best.);
      link writeInputData;
    end;
    when ('WRITTEN_TO_DATA_SET') do;
      ** NOTE: The data set % has % observations and % variables.;
      outputType= 'SAS';
      outputName = upcase (scan (line, 5, ' :'));
      outputObs = input (scan (line, 7, ' :'), best.);
      outputVars = input (scan (line, 10, ' :'), best.);
      link writeOutputData;
    end;
    when ('ROWS_INSERTED') do;
      outputType = 'SAS';
      outputName = upcase (scan (line, 7, ': '));
      outputObs = .;
      outputVars = .;
      link writeOutputData;
    end;
    when ('ROWS_UPDATED') do;
      outputType = 'SAS';
      outputName = upcase (scan (line, 7, ': '));
      outputObs = .;
      outputVars = .;
      link writeOutputData;
    end;
    when ('ROWS_DELETED') do;
      outputType = 'SAS';
      outputName = upcase (scan (line, 7, ': '));
      outputObs = .;
      outputVars = .;
      link writeOutputData;
    end;
    when ('FILE_LIB_IS') do;
      ** NOTE: The file library % is:;
      libType = 'SEQ';
      libName = upcase (scan (line, 5, ' :'));
      _p+1;
      set &_logData. point=_p nobs=_n;
      select (exp);
        when ('DSNAME') do;
          ** %DSNAME=%;
          libFileName = 
            %rdsLRSASMessagesCPUP (%str (scan(line, 2, ' =')));
          output &libData.;
        end;
        otherwise
          _p+(-1);
      end;
    end;
    when ('FILE_IS') do;
      ** NOTE: The file % is:;
      libType = 'SEQ';
      libName = upcase (scan (line, 4, ' :'));
      _p0 = _p;
      ** Find next line like "%=%";
      do _i=1 to 3 until (index (line,"="));
        _p+1;
        set &_logData. point=_p nobs=_n;
      end;
      %macro rdsLRSASMessageFILEIS (separators=%str(' ='));
        if index (line,"=") then do;
          libFileName =
            %rdsLRSASMessagesCPUP (%str (scan(line, 2, &separators.)));
          do until (index (line,"=") or line = '' or exp ^= '');
            _p+1;
            set &_logData. point=_p nobs=_n;
            if not (index (line,"=") or line = '' or exp ^= '') then
              libFileName = trim(libFileName) !! left(trim(line));
          end;
        end;
        output &libData.;
      %mend rdsLRSASMessageFILEIS;
      select (exp);
        when ('DSNAME') do;
          ** %DSNAME=%;
          %rdsLRSASMessageFILEIS;
        end;
        when ('FILENAME') do;
          ** %FILENAME=%;
          %rdsLRSASMessageFILEIS;
        end;
        when ('SESSION') do;
          ** %SESSION=%;
          %rdsLRSASMessageFILEIS;
        end;
        when ('DATEINAME') do;
          ** %Dateiname=%;
          %rdsLRSASMessageFILEIS(separators=%str('='));
        end;
        otherwise;
      end;
      _p=_p0;
    end;
    when ('WRITTEN_TO_FILE_LIB') do;
      ** NOTE: A total of % records were written to the file library %;
      outputType = 'SEQ';
      outputName = upcase (scan (line, 13, ' :'));
      outputObs  = input (scan (line, 5, ' :'), best.);
      outputVars = .;
      link writeOutputData;
    end;
    when ('WRITTEN_TO_FILE') do;
      ** NOTE: % records were written to the file %.;
      outputType = 'SEQ';
      outputName =
        %rdsLRSASMessagesCPUP (%str (scan (line, 9, ' :')));  
      outputObs  = input (scan (line, 2, ' :'), best.);
      outputVars = .;
      link writeOutputData;
    end;
    when ('TABLE_CREATED') do;
      ** NOTE: Table % created, with % rows and % columns%;
      outputType = 'SAS';
      outputName = upcase (scan (line, 3, ' :,'));
      outputObs  = input (scan (line, 6, ' :,'), best.);
      outputVars = input (scan (line, 9, ' :,'), best.);
      link writeOutputData;
    end;
    when ('LIBREF_ASSIGNED') do;
      ** NOTE: Libref % was successfully assigned as follows:%;
      libType = 'SAS';
      libName = upcase (scan (line, 3, ' :'));
      * Search next 10 lines (there might by peage headers);
      do _i=1 to 10;
        _p+1;
        set &_logData. point=_p nobs=_n;
        select (exp);
          when ('LIBNAME_ENGINE') do;
            ** %Engine: %;
            _j = index (line, ':') + 2;
            libEngine = left (substr (line, _j));
          end;
          when ('PHYSICAL_NAME') do;
            ** %Physical Name: %;
            _j = index (line, ':') + 2;
            libFileName = 
              %rdsLRSASMessagesCPUP (%str (substr (line, _j)));
            output &libData.;
          end;
          otherwise;
        end;
      end;
      _p+(-10);
    end;
    when ('LOG_PAGE_HEADER') do;
      ** <page number> The SAS System <date and time>;
      retain logDateTime;
      __line = compbl(line);
	  if prxmatch(pattern_title, __line) > 0 then 
	  do;
	  _line = line;
      _line = left (reverse (substr (reverse (trim (_line)), 1, 30)));
      logDatetime = 
        input(substr(_line,index(_line,',')+1), ANYDTDTE30.)
        * 24 * 3600 + input(substr(_line,1,5), time5.);
	  end ;	
       drop _line __line;
    end;

  %end;

%mend;
