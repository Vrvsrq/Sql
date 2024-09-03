-- Создание таблицы Должность

create table [onb].[Post] (
    [ID] int not null identity, 
    [Code] varchar(255) not null, 
    [Name] varchar(255) not null, 
    constraint [PK_Post] primary key clustered ([ID])
)
alter table [onb].[Post]
    add constraint [UK_Post_Code] unique ([Code]);

-- Создание таблицы "Сотрудник"

create table [onb].[Employee] (
    [ID] int not null identity,
	[Code] as 'E' + cast(ID as varchar(50)) persisted,
    [FullName] varchar(255) not null, 
    [DateBirth] date not null, 
    [DateEmployment] date null, 
    [DateDismissal] date null, 
    constraint [PK_Employee] primary key clustered ([ID])
)
alter table [onb].[Employee]
    add constraint [UK_Employee_Code] unique ([Code]);

-- Создание таблицы "Должности сотрудника"

create table [onb].[Employee_Post] (
    [ID] int not null identity, 
    [ID_Employee] int not null, 
    [ID_Post] int not null, 
    [DateBegin] date not null, 
    [DateEnd] date null, 
    constraint [PK_Employee_Post] primary key clustered ([ID])
)
alter table [onb].[Employee_Post]
    add constraint [FK_Employee_Employee_Post_ID_Employee] foreign key ([ID_Employee]) 
    references [onb].[Employee]([ID]) on delete no action on update no action
alter table [onb].[Employee_Post]
    add constraint [FK_Post_Employee_Post_ID_Post] foreign key ([ID_Post]) 
    references [onb].[Post]([ID]) on delete no action on update no action
alter table [onb].[Employee_Post] 
    add constraint [UK_Employee_Post_ID_Employee_DateBegin] unique (ID_Employee, DateBegin);

-- Создание таблицы "Заявления"

create table [onb].[Statement] (
    [ID] int not null identity, 
    [DateRegistration] date not null, 
    [ID_Employee] int not null, 
    [Content] varchar(1200) null, 
    constraint [PK_Statement] primary key clustered ([ID])
)
alter table [onb].[Statement]
    add constraint [FK_Employee_Statement_ID_Employee] foreign key ([ID_Employee])
    references [onb].[Employee]([ID]) on delete no action on update no action

CREATE VIEW onb.viev_Employee AS 
SELECT 
    ID, 
    CAST(CASE 
        WHEN COALESCE(DateEmployment, CAST(GETDATE() AS DATE)) <= CAST(GETDATE() AS DATE) 
             AND COALESCE(DateDismissal, '2100-01-01') > CAST(GETDATE() AS DATE) 
        THEN 1 
        ELSE 0 
    END AS BIT) AS FlagWorking 
FROM 
    onb.Employee;
   