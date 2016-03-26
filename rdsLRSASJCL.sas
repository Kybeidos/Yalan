%macro rdsLRSASJCL (method);

  /**
  * === rdsLRSASJCL ====================================================
  *
  * rdsLRSASJCL - A macro to identify and parse jcl messages of
  *    sas jobs running on os390
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
  * ===
  *
  *  This macro is part of the Yalan library to analyze SAS(r) logs.
  *
  *  Yalan - Yet another log analyzer.
  *
  *  Note: You will find more information on Yalan at www.redscope.org.
  *
  * === Changes
  *
  * 2005-02-20  sfrenzel(at)kybeidos.de
  *
  *   Initial version.
  *
  * 2005-10-24  sfrenzel@kybeidos.de
  *
  *   Formatting, Header, Finalize Version 0.8
  */

  /**
  * Method: declare
  */
  %if (%lowcase (&method.) = %lowcase (declare)) %then %do;

    libType
      format=$3.
      label='Type of library'
    libName
      format=$32.
      label='Logical name of library'
    libFileName
      format=$256.
      label='Physical name of library'
    date
      format=yymmdd10.
      label='Date'
    time
      format=time10.
      label='Time'

  %end;

  /**
  * Method: identifyLines
  */
  %if (%lowcase (&method.) = %lowcase (identifyLines)) %then %do;

    when
      (line like
       '%IGD101I SMS ALLOCATED TO DDNAME%(%)%')
      then 'SMS_ALLOCATED'
    when
      (line like '%DSN (%)%')
      then 'SMS_ALLOCATED_DSN'
    when
      (line like
       '%IGD104I%RETAINED%')
      then 'ALLOCATION_RETAINED'
    when
      (line like '%JOB%----%----')
      then 'JES_DATE'

  %end;

  /**
  * Method: parseLines
  */
  %if (%lowcase (&method.) = %lowcase (parseLines)) %then %do;

    when ('SMS_ALLOCATED') do;
      ** IGD101I SMS ALLOCATED TO DDNAME;
      libType = 'SAS';
      libName = scan (line, 2, '()');
      _p+1;
      set &_logData. point=_p nobs=_n;
      select (exp);
        when ('SMS_ALLOCATED_DSN') do;
          ** %DSN(%)%;
          libFileName = scan(line, 2, '()');
          output &libData.;
        end;
        otherwise
          _p+(-1);
      end;
    end;
    when ('ALLOCATION_RETAINED') do;
      ** IGD104I ... RETAINED, DDNAME= ...;
      libType = 'SAS';
      libFileName = scan (line, 2, ' ,=');
      libName = scan (line, 5, ' ,=');
      output &libData.;
    end;
    when ('JES_DATE') do;
      ** 9.30.44 JOB30454 ---- WEDNESDAY, 26 JAN 2005 ----;
      _time = input (scan(line,1,' '), time10.);
      _date =
        input(compress(substr(left(scan(line,2,',')),1,12)),date9.);
      if (_date and _time) then do;
        time = _time;
        date = _date;
      end;
    end;

  %end;

%mend;
