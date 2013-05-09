Net-Migrater-v4.5
=================

Powershell script for migrating from .net framework 4.0 migration to 4.5

How to Use:- 

1.  Copy the script main directory where your solution resides.

2.	Navigate to that directory. (by change directory command)

3.	In Powershell window, type Set-ExecutionPolicy RemoteSigned –Force

4.	And then type migrator4.5.ps1





This script will only change:- 

1.	TargetFrameworkVersion attribute from 4.0 to 4.5 in all csproj files

2.	Remove TargetFrameworkProfile innerText (Not required for 4.5 framework)

3.	Add Prefer32Bit xml tag (This tag is available from .net 4.5 and Visual Studio 11) 

4.	Modify supported runtime of all App.config file to “.NETFramework,Version=v4.5”
