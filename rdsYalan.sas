%macro rdsYalan (method, value1, value2);

  /**
  * === rdsYalan ======================================================
  *
  * rdsYalan - A SAS(r) macro which implements an analyzer for sas logs
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
  *
  * In case you wonder why we use the lowcase-function to query the
  * method, try this:
  *
  * %macro say (what);
  *   %if &what. = five %then %do;
  *     5
  *   %end;
  * %mend;
  *
  * %macro doto;
  *   %do i=1 %to %say(five);
  *     %put &i.;
  *   %end;
  * %mend;
  *
  * %doto;
  *
  * This will not work, since the string "five" in the do-statement
  * will be passed in upper case to the macro say. Don't ask why!
  *
  * === Changes
  *
  * 2004-06-24  sfrenzel@kybeidos.de
  *
  *   Initial version
  *
  * 2005-01-24  sfrenzel@kybeidos.de
  *
  *   Formatting for OS390 (72 cols max)
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  *
  */

  %global
    RDSYALAN_LogFileNameCount
    RDSYALAN_LDBLibname
    RDSYALAN_LDBLibrary
    RDSYALAN_PollingInterval
    RDSYALAN_CommandFile
  ;

  /*
  * Initialize internal variables
  */
  %if (%length(&RDSYALAN_LogFileNameCount.) = 0) %then %do;
    %let RDSYALAN_LogFileNameCount = 0;
  %end;
  %if %length (&RDSYALAN_LDBLibname.) = 0 %then %do;
    %let RDSYALAN_LDBLibname = %rdsLibrary (getUniqueLibname);
  %end;
  %if %length (&RDSYALAN_PollingInterval.) = 0 %then %do;
    %let RDSYALAN_PollingInterval = 300;
  %end;

  /**
  * Method: getLogFileNameCount
  */
  %if (%lowcase (&method.) = %lowcase (getLogFileNameCount)) %then %do;
    &RDSYALAN_LogFileNameCount.
  %end;

  /**
  * Method: getLDBLibname
  */
  %if (%lowcase (&method.) = %lowcase (getLDBLibname)) %then %do;
    &RDSYALAN_LDBLibname.
  %end;

  /**
  * Method: getLDBLibrary
  */
  %if (%lowcase (&method.) = %lowcase (getLDBLibrary)) %then %do;
    &RDSYALAN_LDBLibrary.
  %end;

  /**
  * Method: setLDBLibrary
  */
  %if (%lowcase (&method.) = %lowcase (setLDBLibrary)) %then %do;
    %let RDSYALAN_LDBLibrary = &value1.;
    libname &RDSYALAN_LDBLibname "&RDSYALAN_LDBLibrary."
      %if %length (&value2.) ne 0 %then %do;
        server = &value2.
      %end;
    ;
  %end;

  /**
  * Method: getPollingInterval
  */
  %if (%lowcase (&method.) = %lowcase (getPollingInterval)) %then %do;
    &RDSYALAN_PollingInterval.
  %end;

  /**
  * Method: setPollingInterval
  */
  %if (%lowcase (&method.) = %lowcase (setPollingInterval)) %then %do;
    %let RDSYALAN_PollingInterval = &value1.;
  %end;

  /**
  * Method: getCommandFile
  */
  %if (%lowcase (&method.) = %lowcase (getCommandFile)) %then %do;
    &RDSYALAN_CommandFile.
  %end;

  /**
  * Method: setCommandFile
  */
  %if (%lowcase (&method.) = %lowcase (setCommandFile)) %then %do;
    %let RDSYALAN_CommandFile = &value1.;
  %end;

  /**
  * Method: addLogFiles
  */
  %if (%lowcase (&method.) = %lowcase (addLogFiles)) %then %do;
    %local _exists _i;
    %let _exists = 0;
    %do _i=1 %to &RDSYALAN_LogFileNameCount.;
      %if (    "&&RDSYALAN_LFD&_i." = "&value1."
           and "&&RDSYALAN_LFP&_i." = "&value2."
          ) %then
        %let _exists = 1;
    %end;
    %if (&_exists. = 0) %then %do;
      %let RDSYALAN_LogFileNameCount = %eval(&RDSYALAN_LogFileNameCount. + 1);
      %* Declare new global variable "rdsYalanLFN<n>", "rdsYalanLDN<n>";
      %global RDSYALAN_LFD&RDSYALAN_LogFileNameCount.;
      %global RDSYALAN_LFP&RDSYALAN_LogFileNameCount.;
      %let RDSYALAN_LFD&RDSYALAN_LogFileNameCount. = &value1.;
      %let RDSYALAN_LFP&RDSYALAN_LogFileNameCount. = &value2.;
    %end;
  %end;

  /**
  * Method: resetLogFiles
  */
  %if (%lowcase (&method.) = %lowcase (resetLogFiles)) %then %do;
    data _null_;
      do _i=1 to &RDSYALAN_LogFileNameCount.;
        call symdel ('RDSYALAN_LFD'!!left(put(_i,best.)));
        call symdel ('RDSYALAN_LFP'!!left(put(_i,best.)));
      end;
    run;
    %let RDSYALAN_LogFileNameCount = 0;
  %end;

  /**
  * Method: getLogFileDirectory
  */
  %if (%lowcase (&method.) = %lowcase (getLogFileDirectory)) %then %do;
    &&RDSYALAN_LFD&value1.
  %end;

  /**
  * Method: getLogFilePattern
  */
  %if (%lowcase (&method.) = %lowcase (getLogFilePattern)) %then %do;
    &&RDSYALAN_LFP&value1.
  %end;

  /**
  * Method: startDaemon
  */
  %if (%lowcase (&method.) = %lowcase (startDaemon)) %then %do;
    %rdsLogFilePoller(start);
  %end;

  /**
  * Method: stopDaemon
  */
  %if (%lowcase (&method.) = %lowcase (stopDaemon)) %then %do;
    %rdsLogFilePoller(stop);
  %end;

%mend;
