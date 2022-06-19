#require "rddsql"
#require "sddmy"

#include "dbinfo.ch"
#include "error.ch"

REQUEST SDDMY, SQLMIX
//REQUEST HB_CODEPAGE_PLWIN

ANNOUNCE RDDSYS

FIELD RESIDENTS

PROCEDURE Main()

#if defined( __HBSCRIPT__HBSHELL )
   rddRegister( "SQLBASE" )
   rddRegister( "SQLMIX" )
   hb_SDDMY_Register()
#endif

   //HB_CDPSELECT('PLWIN')
   //HB_LANGSELECT('PL')
   rddSetDefault( "SQLMIX" )

   AEval( rddList(), {| x | QOut( x ) } )
   //host,user,password,db,port,socket,flags

   IF rddInfo( RDDI_CONNECT, { "MYSQL", "10.245.254.237", "SYSDBA","masterkey","Paragony"} ) == 0
      ? dbinfo(65) //"Unable connect to the server"
      RETURN
   ENDIF
   rddInfo( RDDI_EXECUTE, "SET CHARACTER SET cp852")
//   CreateTable()

   ? "Let's browse table (press any key)"
   Inkey( 0 )
   dbUseArea( .T., , "SELECT * FROM country", "country" )
   Browse()

   ? "Let's browse table ordered by resident count (press any key)"
   Inkey( 0 )
   INDEX ON RESIDENTS TAG residents TO country
   Browse()

   dbCloseAll()

   RETURN

STATIC PROCEDURE CreateTable()

   ? rddInfo( RDDI_EXECUTE, "DROP TABLE country" )
   ? rddInfo( RDDI_EXECUTE, "CREATE TABLE country (CODE char(3), NAME char(50), RESIDENTS int(11))" )
   ? rddInfo( RDDI_EXECUTE, "INSERT INTO country values ('LTU', 'Lithuania', 3369600), ('USA', 'United States of America', 305397000), ('POR', 'Portugal', 10617600), ('POL', 'Poland', 38115967), ('AUS', 'Australia', 21446187), ('FRA', 'France', 64473140), ('RUS', 'Russia', 141900000)" )

   RETURN
