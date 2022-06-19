/*
 * Converts a .dbf file into a MySQL table
 *
 * Copyright 2000 Maurilio Longo <maurilio.longo@libero.it>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file LICENSE.txt.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
 *
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#command DEFAULT <x> TO <y> => IF (<x>)=NIL;<x>:=<y>;ENDIF

#require "hbmysql"

REQUEST DBFCDX

#include "inkey.ch"

STATIC oServer, lCreateTable := .F.

PROCEDURE Main( ... )

   LOCAL cTok
   LOCAL cHostName := "evo"
   LOCAL cUser := "SYSDBA"
   LOCAL cPassWord := "masterkey"
   LOCAL cDataBase, cTable, cFile, oBrowser, oTable
   LOCAL i

   altd()
   Set( _SET_DATEFORMAT, "yyyy-mm-dd" )
   SET DELETED ON

//   REQUEST HB_LANG_PL
//   HB_LANGSELECT('PL')
//   REQUEST HB_CODEPAGE_PL852
//   HB_CDPSELECT('PL852')

 
   // At present time (2000-10-23) DBFCDX is default RDD and DBFNTX is
   // now DBF (I mean the one able to handle .dbt-s :-))
   rddSetDefault( "DBFNTX" )

   IF PCount() < 4
      help()
      QUIT
   ENDIF

   i := 1
   // Scan parameters and setup workings
   DO WHILE i <= PCount()

      cTok := hb_PValue( i++ )

      DO CASE
      CASE cTok == "-h"
         cHostName := hb_PValue( i++ )

      CASE cTok == "-d"
         cDataBase := Lower(hb_PValue( i++ ))

      CASE cTok == "-t"
         cTable := Lower(hb_PValue( i++ ))

      CASE cTok == "-f"
         cFile := hb_PValue( i++ )

      CASE cTok == "-u"
         cUser := hb_PValue( i++ )

      CASE cTok == "-p"
         cPassWord := hb_PValue( i++ )

      CASE cTok == "-c"
         lCreateTable := .T.

      OTHERWISE
         help()
         QUIT
      ENDCASE
   ENDDO

   oServer := TMySQLServer():New( cHostName, cUser, cPassWord )
   IF oServer:NetErr()
      ? oServer:Error()
      QUIT
   ENDIF

   //oServer:Query("SET CHARACTER SET = utf8")

   mysql_set_character_set(oServer:nSocket,'cp852')

   //oServer:Query("SET sql_mode = 'PAD_CHAR_TO_FULL_LENGTH'")
   oServer:Query("CREATE DATABASE IF NOT EXISTS "+cDataBase+" COLLATE utf8mb4_pl_0900_ai_ci")

   oServer:SelectDB( cDataBase )
   IF oServer:NetErr()
      ? oServer:Error()
      QUIT
   ENDIF
   
   if empty(cFile)
      oTable := oServer:Query("SELECT * FROM `"+cTable+"`")
      oBrowser := TBrowseSQL():New( 1, 1, maxrow() -1 , maxcol() - 1, oServer, oTable, cTable )
      @ 0, 0, maxrow(), maxcol() box "ÚÍ¿³ÙÍÀ³"
      @ 2, 0 say "Ã"
      @ 2, maxcol() say "´"
      oBrowser:headSep := " Í"
      oBrowser:BrowseTable(.t.)
      oBrowser := NIL
      //oTable:sql_Commit()
      oTable := NIL


   elseif lower(right(cFile,4))<>'.dbf'
      i:=RAT(HB_PS(),cfile)
      SET DEFAULT TO (LEFT(cfile,i))
      AEVAL(DIRECTORY(cfile+"*.dbf"),{|X|CHGDAT(X[1],,lCreateTable)})
   else
      CHGDAT(cFile,cTable,lCreateTable)
   end if
   
   oServer:Destroy()

   RETURN

static proc chgdat(cFile, cTable, lCreateTable)
   LOCAL oTable, oRecord, aDbfStruct, i

   IF File(strtran(cFile,subs(cFile,-3),'fpt'))
     i:='DBFCDX'
   ENDIF
   dbUseArea( .f., i, cFile,,.F., .T. )
   if indexord()<>0
      SET ORDER TO 0
      GO TOP
   end if
   
   aDbfStruct := dbStruct()

   if empty(cTable)
      cTable:= lower(Alias())
   end if

   begin sequence
      IF lCreateTable
         IF hb_AScan( oServer:ListTables(), cTable,,, .T. ) > 0
            oServer:DeleteTable( cTable )
            IF oServer:NetErr()
               ? oServer:Error()
               break
            ENDIF
         ENDIF
         oServer:CreateTable( cTable, aDbfStruct )
         IF oServer:NetErr()
            ? oServer:Error()
            break
         ENDIF
      ENDIF

      // Initialize MySQL table
      oTable := oServer:Query( "SELECT * FROM `" + cTable + "` LIMIT 1" )
      IF oTable:NetErr()
         Alert( oTable:Error() )
         break
      ENDIF

      DO WHILE ! Eof() .AND. Inkey() != K_ESC

         oRecord := oTable:GetBlankRow()

         FOR i := 1 TO FCount()
            oRecord:FieldPut( i, FieldGet( i ) )
         NEXT
         
         oTable:Append( oRecord )
         IF oTable:NetErr()
            Alert( oTable:Error() )
            break
         ENDIF

         dbSkip()

         DevPos( Row(), 1 )
         IF ( RecNo() % 100 ) == 0
            DevOut( "imported recs: " + hb_ntos( RecNo() ) )
         ENDIF
      ENDDO
   recover
   end
   dbCloseArea()
   oTable := NIL
   RETURN

PROCEDURE Help()

   ? "dbf2MySQL - dbf file to MySQL table conversion utility"
   ? "-h hostname (default: localhost)"
   ? "-u user (default: root)"
   ? "-p password (default no password)"
   ? "-d name of database to use"
   ? "-t name of table to add records to"
   ? "-c delete existing table and create a new one"
   ? "-f name of .dbf file to import"
   ? "all parameters but -h -u -p -c are mandatory"
   ? ""

   RETURN
