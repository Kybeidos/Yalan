%macro rdsFile (method, prefix=file);

  /**
  * === rdsFile =======================================================
  *
  * rdsFileName - A SAS(r) macro which implements some methods to
  *   handle external files in SAS(r).
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
  * WITHOUT ANY WARRANTY. without even the implied warranty of
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
  * Method: getUniqueFilename
  *
  *   Returns a filename that is not already in use. The filename
  *   returned is <prefix><number>, where <prefix> is the value of the
  *   parameter "prefix" ("file" by default), and <number> is increased
  *   until a free filename is found.
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
  */

  /**
  * getUniqueFilename
  */
  %if (%lowcase (&method.) = %lowcase (getUniqueFilename)) %then %do;
    %local _i;
    %let _i=1;
    %do %while (%sysfunc(fileref(&prefix.&_i.)) <= 0);
      %let _i=%eval(&_i.+1);
    %end;
    &prefix.&_i.
  %end;

%mend;
