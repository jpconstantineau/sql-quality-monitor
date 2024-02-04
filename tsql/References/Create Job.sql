USE msdb;  
GO  
EXEC sp_add_job  
    @job_name = N'SqlAgentTest',
    @description = N'Backup the Movies database.',
    @category_name = 'Database Maintenance';
GO
EXEC sp_add_jobstep  
    @job_name = N'SqlAgentTest',  
    @step_name = N'Insert data for step 1',  
    @subsystem = N'TSQL',  
    @command = N'USE TestDB; INSERT INTO SqlAgentJobs VALUES (''SqlAgentTest'', 1, SYSDATETIME())',  
    @on_success_action = 3;
GO
EXEC sp_add_jobstep  
    @job_name = N'SqlAgentTest',  
    @step_name = N'Insert data for step 2',  
    @subsystem = N'TSQL',  
    @command = N'USE TestDB; INSERT INTO SqlAgentJobs VALUES (''SqlAgentTest'', 2, SYSDATETIME())',  
    @on_success_action = 1;
GO
EXEC sp_add_schedule 
    @schedule_name = N'Run_Sat_6AM',
    @freq_type = 8,
    @freq_interval = 64,
    @freq_recurrence_factor = 1,
    @active_start_time = 060000;
GO  
EXEC sp_attach_schedule  
   @job_name = N'SqlAgentTest',  
   @schedule_name = N'Run_Sat_6AM';
GO  
EXEC sp_add_jobserver  
    @job_name = N'SqlAgentTest',  
    @server_name = N'(LOCAL)';
GO