REM @ECHO OFF
Call Settings.cmd

@ECHO.
@ECHO.
@ECHO ********************************************************************************
@ECHO.
@ECHO    You are about to run the refresh script for which there is a potential for 
@ECHO    data loss review the settings on the next screen carefully before proceeding
@ECHO.
@ECHO.
@ECHO.        THERE IS NO GOING BACK EASILY AFTER RUNNING THIS
@ECHO.
@ECHO ********************************************************************************
@ECHO.
@ECHO.
@ECHO.
pause

CLS
@ECHO.
@ECHO ********************************************************************************
@ECHO           JOB NAME: %_syncName%
@ECHO             SOURCE: %_SOURCESHARENAME%%_SOURCEPATH%
@ECHO        DESTINATION: %_dest%
@ECHO          SYNC FILE: %_SYNCFILES%
@ECHO      SCRIPT SOURCE: %_REFRESHSCRIPTSOURCE%
@ECHO  SQL SCRIPT SOURCE: %_sqlscriptsource%
@ECHO         SQL SERVER: %_SQLSERVER%
@ECHO       SQL DATABASE: %_SQLSERVERDATABASE%
@ECHO            LOGGING: %_option_LOG%
@ECHO       EXCL FILE(s): %_EXCLUDEFILE%
@ECHO  EXCL DIRECTORY(s): %_EXCLUDEDIRECTORY%
@ECHO ********************************************************************************
@ECHO.
@ECHO Last chance to think about what you are about to do...
pause
@ECHO.
@ECHO.
@ECHO.
@ECHO Ok here we go, do not say you were not warned


REM
REM stop IIS and connect to network share
iisreset /stop
net use * %_SOURCESHARENAME:~0,-1% %_SOURCESHAREUSERPASSWORD% /USER:%_SOURCESHAREUSERNAME%
net use * %_DATABASEBAKSHARE:~0,-1% %_SOURCESHAREUSERPASSWORD% /USER:%_SOURCESHAREUSERNAME%
net use * %_DATABASEBAKTEMPPATH:~0,-1% %_SOURCESHAREUSERPASSWORD% /USER:%_SOURCESHAREUSERNAME%

IF %_SYNCFILES% == false (	
	GOTO DB_SYNC
	)

REM
REM backup server specific files
REM
%_roboCopyPath% %_dest%\bin\ "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%\bin" *.lic /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt
%_roboCopyPath% %_dest%\bin\ "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%\bin" avt.SearchBoost.Core.dll /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt
%_roboCopyPath% %_dest%\config\ "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%\config" CSI.SystemConfiguration.config /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt
%_roboCopyPath% %_dest%\Portals\3\ "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%\Portals\3" GoogleAnalytics.config /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt
%_roboCopyPath% %_dest%\ "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%" web.config /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt


REM
REM perform sync
REM
%_roboCopyPath% %_SOURCESHARENAME%%_SOURCEPATH% %_dest% /MIR /XN %_roboCopy_common_options% /xd %_EXCLUDEDIRECTORY% /xf %_EXCLUDEFILE% /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt


REM
REM copy server specific files
REM
%_roboCopyPath% "%_REFRESHSCRIPTSOURCE%site files\%CurrentDate%_%CurrentTime%" %_dest%\ *.* /E /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt


:DB_SYNC
IF %_SYNCDB% == false (	
	GOTO DONE
	)
REM
REM copy database backup to the database server
REM
%_roboCopyPath% %_DATABASEBAKPATH% %_DATABASEBAKTEMPPATH:~0,-1% %_DATABASEBAKNAME% %_roboCopy_common_options% /xd %_EXCLUDEDIRECTORY% /xf %_EXCLUDEFILE% /LOG+:.\Log\%CurrentDate%_%CurrentTime%_%_syncName%.txt


REM
REM Refresh DNN Development from Production
REM  
SET _SYNCNAME=%_SYNCNAME%_Database

sqlcmd -S %_SQLSERVER% -i "%_sqlscriptsource%Restore database.sql" -v varDB="%_SQLSERVERDATABASE%" varDbBakPath="%_DATABASEBAKPATH%" varDbBakTempPath="%_DATABASEBAKTEMPPATH%" varDbBakName="%_DATABASEBAKNAME%" varDBFilePath="%_DATABASEFILEPATH%" -U sa -P s0909a! -o .\Log\%CurrentDate%_%CurrentTime%_%_syncName%-restore_database.txt
sqlcmd -S %_SQLSERVER% -i "%_sqlscriptsource%Post Restore.sql" -v varDB="%_SQLSERVERDATABASE%" varDNNLICHOSTKEY="%_DNNLICHOSTKEY%" varDNNLICHOSTNAME="%_DNNLICHOSTNAME%" varLDAPSERVER="%_LDAPSERVER%" varHTTPAlias="%_HTTPAlias%" varDNNLICSERVICEENDDATE="%_DNNLICSERVICEENDDATE%" -U sa -P s0909a! -o .\Log\%CurrentDate%_%CurrentTime%_%_syncName%-post_restore.txt


:DONE
REM
REM Clean-up and leave
REM
net use * /DELETE /YES
iisreset /start


REM CLS
@ECHO.
@ECHO The refresh has complete, make sure you check the logs for any errors
@ECHO.
@ECHO   LOGGING: 
@ECHO        .\Log\%CurrentDate%_%CurrentTime%_%_syncName%-restore_database.txt
@ECHO        .\Log\%CurrentDate%_%CurrentTime%_%_syncName%-post_restore.txt
@ECHO.
@ECHO.
pause