 
if not exists(SELECT * FROM sys.schemas WHERE name = 'RetailAnalitics')
begin
 exec('create schema RetailAnalitics');
 end;
 go:


create or alter function RetailAnalitics.ufn_GetOrderEscalationLevel(@salesorderid INT)
returns bit
as 
begin
    declare @LineCount INT;
    
  
    select @LineCount = count(*) 
    from Sales.SalesOrderDetail 
    where SalesOrderID = @salesorderid;
    
    return @LineCount;
end;
go







 create or alter procedure retailanalitics.ups_GetCustomerServiceOrderDiagnostics 
    @salesorderid int,
    @escalationlevel nvarchar(50) output,
    @processingmessage nvarchar(250) output
as
begin
    -- -1 check: id is null
    if @salesorderid is null
    begin
        set @escalationlevel = 'none'
        set @processingmessage = 'error: id is null'
        return -1
    end

    -- -2 check: does it exist
    if not exists (select * from sales.salesorderheader where salesorderid = @salesorderid)
    begin
        set @escalationlevel = 'none'
        set @processingmessage = 'error: order not found'
        return -2
    end

    -- -3 check: check detail lines
    if retailanalitics.ufn_getorderescalationlevel(@salesorderid) = 0
    begin
        set @escalationlevel = 'high'
        set @processingmessage = 'error: no detail lines'
        return -3
    end

    -- 0 check: success path
    declare @status int
    select @status = [status] from sales.salesorderheader where salesorderid = @salesorderid

    if @status = 5
    begin
        set @escalationlevel = 'low'
        set @processingmessage = 'success: order is healthy'
    end
    else
    begin
        set @escalationlevel = 'immediate action'
        set @processingmessage = 'success: status needs attention'
    end

    return 0
end;
go



create or alter procedure retailanalitics.test_order
    @id int
as
begin
    declare @ret int;
    declare @esc nvarchar(50);
    declare @msg nvarchar(250);

    exec @ret = retailanalitics.ups_getcustomerserviceorderdiagnostics 
        @salesorderid = @id, 
        @escalationlevel = @esc output, 
        @processingmessage = @msg output;

    select @ret as [code], @esc as [escalation], @msg as [message];
end;
go






--test cases 

--TC1 
 
declare @returncode int;
declare @escalation nvarchar(50);
declare @message nvarchar(250);

 
exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics 
    43659, 
    @escalation output, 
    @message output;

 
select 
    'tc1 - positional test' as [test case],
    @returncode as [return code], 
    @escalation as [escalation level], 
    @message as [message];
go



--TC2

declare @returncode int;declare @escalation nvarchar(50);declare @message nvarchar(250);

exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics 
    @salesorderid = 43659, 
    @escalationlevel = @escalation output, 
    @processingmessage = @message output;

select 
    'tc2 - named parameter test' as [test case],
    @returncode as [return code], 
    @escalation as [escalation level], 
    @message as [message];


   -- test -3
declare @returncode int;declare @escalation nvarchar(50);
declare @message nvarchar(250);exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics    
@salesorderid = null, 
    @escalationlevel = @escalation output, 
    @processingmessage = @message output;
    select 
    'tc2 - null sales order id check' as [test case],
    @escalation as [captured escalation level];


--test 4
 
begin transaction;

 
declare @fakeid int;
select top 1 @fakeid = salesorderid from sales.salesorderheader;

 
delete from sales.salesorderdetail where salesorderid = @fakeid;

 
declare @returncode int;declare @escalation nvarchar(50);declare @message nvarchar(250);exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics     @salesorderid = @fakeid, 
    @escalationlevel = @escalation output, 
    @processingmessage = @message output;select 
    'tc4 - no detail lines check' as [test case],
    @message as [captured processing message];
     
rollback transaction;


--test 5
 
begin transaction;

 
declare @fakeid int;
select top 1 @fakeid = salesorderid from sales.salesorderheader;
 
delete from sales.salesorderdetail where salesorderid = @fakeid;
 
declare @returncode int;declare @escalation nvarchar(50);declare @message nvarchar(250);exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics     @salesorderid = @fakeid, 
    @escalationlevel = @escalation output, 
    @processingmessage = @message output;select 
    'tc4 - return code check' as [test case],
    @returncode as [captured return code];

 
rollback transaction;
    
  

--test 6 

declare @returncode int;declare @escalation nvarchar(50);declare @message nvarchar(250);

 
begin try
    exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics 
        @salesorderid = 'NOT-AN-ID', -- invalid sales ID string
        @escalationlevel = @escalation output, 
        @processingmessage = @message output;
end try
begin catch
    set @returncode = error_number();
end catch

select 
    'tc5 - invalid sales id check' as [test case],
    @returncode as [captured return code];

-- test 7

declare @returncode int;declare @escalation nvarchar(50);declare @message nvarchar(250);exec @returncode = retailanalitics.ups_getcustomerserviceorderdiagnostics     @salesorderid = null, 
    @escalationlevel = @escalation output, 
    @processingmessage = @message output;select 
    'tc2 - null sales order id check' as [test case],
    @returncode as [captured return code];