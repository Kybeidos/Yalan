%let YalanPath = %str(C:\Users\&sysuserid.\Yalan);
filename yalanmac "&YalanPath.";
options sasautos=(sasautos yalanmac);
options mprint source source2 notes;

%macro rdsStartYalan;

  /**
  *  === rdsStartYalan ==================================================
  *
  *  rdsStartYalan - Configuration of environment, start of deamon
  *
  *  Note: SAS is a registered trademark of SAS Institute Inc.
  *    (www.sas.com)
  *
  *  === License
  *
  *   Copyright (c) 2005-2016 KYBEIDOS GmbH (www.kybeidos.de)
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
  *  2015-04-29  sfrenzel@kybeidos.de
  *
  *   Interpretation of Libname Engine
  *   Apply "upcase()" to inputName, outputName, libName
  */

  %* Reset configuration;
  %rdsYalan (resetLogFiles);

  %* Where to look for new log files;
  %rdsYalan (addLogFiles, C:\Users\&sysuserid.\YalanLogs, *);
  
  %* In which time intervall to look for new log files;
  %rdsYalan (setPollingInterval, 15);

  %* Set the library (e.g. "c:/MyLDB") to write the log database to and (optionally)
     name the share server to access the log database (e.g. "sassrvt1");
  %* SYSTASK command %unquote(%nrbquote('MD "C:\Users\&sysuserid.\LogAnalyse\logdb_demo"')) WAIT ;
  %rdsYalan (setLDBLibrary, C:\Users\&sysuserid.\YalanLogDB);

  %* Yalan will execute the statements contained in the following file every time
     it polls for new log files. You may stop the Yalan Daemon by passing the
     following statement via this file: %rdsYalan (stopDaemon);
  %rdsYalan (setCommandFile, &YalanPath.\yalanCmds.sas);

  %* Start the Yalan daemon;
  %rdsYalan (startDaemon);

%mend;

%rdsStartYalan;

/*
%* To test single Yalan macros proceed as follows;
%* ... include changed macros as needed, i.e.;
%include "&YalanPath.\rdsLogReaderSAS.sas";
%include "&YalanPath.\rdsLRSASMessages.sas";
%* ... read a single log file to test your changes;
%let logPath = C:\Users\&sysuserid.\YalanLogs;
%rdsLogReaderSAS (readLog, logFileName = &logPath./SampleLog);
*/
