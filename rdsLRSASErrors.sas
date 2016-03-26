%macro rdsLRSASErrors (method);

  /**
  * === rdsLRSASErrors ================================================
  *
  * rdsLRSASErrors - A macro to identify and parse sas(r) error
  *   messages
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
  *  This program is distributed in the hope that it will be useful,
  *  but WITHOUT ANY WARRANTY; without even the implied warranty of
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

    errorMessage
      format=$256.
      label='Error Message'
    errorSeverity
      format=3.
      label='Severity of Error'

  %end;

  /**
  * Method: identifyLines
  */
  %if (%lowcase (&method.) = %lowcase (identifyLines)) %then %do;

    when
      (line like
       '%NOTE: Variable % is uninitialized%')
      then 'VARIABLE_UNINITIALIZED'
    when
      (line like
       '%NOTE: Invalid % argument%')
      then 'INVALID_ARGUMENT'
    when
      (line like
       'ERROR %-%:%')
      then 'SEVERE_ERROR'
    when
      (line like
       '%ERROR: Libname % is not assigned.')
      then 'LIBNAME_NOT_ASSIGNED'
    when
      (line like '%NOTE: % repeats of BY values.%')
      then 'REPEATS_OF_BY_VALUES'

  %end;

  /**
  * Method: parseLines
  */
  %if (%lowcase (&method.) = %lowcase (parseLines)) %then %do;

    when ('VARIABLE_UNINITIALIZED') do;
      errorMessage = line;
      errorSeverity = 4;
      link writeErrorData;
    end;
    when ('INVALID_ARGUMENT') do;
      errorMessage = line;
      errorSeverity = 4;
      link writeErrorData;
    end;
    when ('SEVERE_ERROR') do;
      errorMessage = line;
      errorSeverity = 12;
      link writeErrorData;
    end;
    when ('LIBNAME_NOT_ASSIGNED') do;
      errorMessage = line;
      errorSeverity = 8;
      link writeErrorData;
    end;
    when ('REPEATS_OF_BY_VALUES') do;
      errorMessage = line;
      errorSeverity = 8;
      link writeErrorData;
    end;

  %end;

%mend;
