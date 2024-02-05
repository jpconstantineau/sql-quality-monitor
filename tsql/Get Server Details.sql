USE master
GO

	EXEC xp_msver "ProductName"
	  ,"ProductVersion"
	  ,"Language"
	  ,"Platform"
	  ,"WindowsVersion"
	  ,"PhysicalMemory"
	  ,"ProcessorCount"
	GO


	 SELECT convert(varchar(128),SERVERPROPERTY('ServerName')) as ServerName,
	 convert(varchar(128),SERVERPROPERTY('Edition')) as Edition,
	 convert(varchar(128),SERVERPROPERTY('MachineName')) as MachineName,
	 convert(varchar(128),SERVERPROPERTY('InstanceName')) as InstanceName,
	 convert(varchar(128),SERVERPROPERTY('ProductBuild')) as ProductBuild,
	 convert(varchar(128),SERVERPROPERTY('ProductLevel')) as ProductLevel,
	 convert(varchar(128),SERVERPROPERTY('ProductUpdateLevel')) as ProductUpdateLevel,
	 convert(varchar(128),SERVERPROPERTY('ProductVersion')) as ProductVersion,
	  convert(varchar(128),SERVERPROPERTY('EngineEdition')) as EngineEdition,
	 convert(varchar(128),SERVERPROPERTY('BuildClrVersion')) as BuildClrVersion


	 
	 
	 
	 
	 
	 
