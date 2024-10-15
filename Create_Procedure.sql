/* Создаем процедуру которая будет выводить данные о суммах начислений 
и суммах долга по срокам для указанного лицевого счета на указанную дату в параметрах.*/

create or alter procedure dbo.RPT_Subscrs_Debts_By_Term
    @F_Subscr int, -- Идентификатор ЛС
    @D_Date date   -- Дата, от которой высчитывается срок начисления
as
begin
    set nocount on;
	select 
        s.C_Number as [Номер ЛС],
        s.C_FirstName + ' ' + s.C_SecondName AS [ФИО],
        s.C_Address as [Адрес],
        b.C_Sale_items as [Услуга],

        -- Начисления и долги до 30 дней
		sum(case when datediff(day, b.D_Date, @D_Date) <= 30 then b.N_Amount else 0 end) as [Нач. до 30 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) <= 30 then b.N_Amount_Rest else 0 end) as [Долг до 30 дней],

        -- Начисления и долги от 31 до 180 дней
		sum(case when datediff(day, b.D_Date, @D_Date) between 31 and 180 then b.N_Amount else 0 end) as [Нач. от 31 до 180 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) between 31 and 180 then b.N_Amount_Rest else 0 end) as [Долг. от 31 до 180 дней],

        -- Начисления и долги свыше 181 дня
		sum(case when datediff(day, b.D_Date, @D_Date) > 180 then b.N_Amount else 0 end) as [Нач. свыше 181 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) > 180 then b.N_Amount_Rest else 0 end) as [Долг свыше 181 дней]
	from
        dbo.SD_Subscrs as s
	left join
	    dbo.FD_Bills as b on s.LINK = b.F_Subscr
	where
        s.LINK = @F_Subscr -- Фильтруем по идентификатору ЛС

    -- Групппировка, чтобы получить итоговые суммы по каждому лицевому счету
	group by
		s.C_Number,
		s.C_FirstName,
		s.C_SecondName,
		s.C_Address,
		b.C_Sale_Items

    -- Объединяем, чтобы получить общую сумму по всем услугам по каждому лицевому счету
    union all 
    select 
        s.C_Number as [Номер ЛС],
        s.C_FirstName + ' ' + s.C_SecondName AS [ФИО],
        s.C_Address as [Адрес],
        'Все' as [Услуга],
		sum(case when datediff(day, b.D_Date, @D_Date) <= 30 then b.N_Amount else 0 end) as [Нач. до 30 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) <= 30 then b.N_Amount_Rest else 0 end) as [Долг до 30 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) between 31 and 180 then b.N_Amount else 0 end) as [Нач. от 31 до 180 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) between 31 and 180 then b.N_Amount_Rest else 0 end) as [Долг. от 31 до 180 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) > 180 then b.N_Amount else 0 end) as [Нач. свыше 181 дней],
		sum(case when datediff(day, b.D_Date, @D_Date) > 180 then b.N_Amount_Rest else 0 end) as [Долг свыше 181 дней]
	from
        dbo.SD_Subscrs as s
	left join
	    dbo.FD_Bills as b on s.LINK = b.F_Subscr
	where
    s.LINK = @F_Subscr
	group by
		s.C_Number,
		s.C_FirstName,
		s.C_SecondName,
		s.C_Address
end;
go

/* Создаем процедуру которая будет выводить данные о суммах начислений и суммах долга 
за указанный год для указанного лицевого счета в параметрах по каждому месяцу с одним итогом.
С возможностью посмотреть вывести данные с детализаций по услугам и без. */

create or alter procedure dbo.RPT_Subscrs_Debts_By_Year
    @F_Subscr int,       -- Идентификатор ЛС
    @N_Year int,         -- Год в числовом формате
    @B_Detail bit        -- Битовый параметр для детализации
as
begin
    set nocount on;
    if @B_Detail = 1
    begin

        -- Запрос с детализацией
        select
            s.C_Number as [Номер ЛС],
            s.C_FirstName + ' ' + s.C_SecondName as [ФИО],
            s.C_Address as [Адрес],
            format(b.D_Date, 'MM.yyyy') as [Месяц],
            b.C_Sale_Items as [Услуга],
            sum(b.N_Amount) as [Сумма начисления],
            sum(b.N_Amount_Rest) as [Сумма долга]
        from
            dbo.SD_Subscrs as s
        left join
            dbo.FD_Bills as b on s.LINK = b.F_Subscr
        where
            s.LINK = @F_Subscr and year(b.D_Date) = @N_Year -- Фильтруем по ЛС и году
        group by 
            s.C_Number,
            s.C_FirstName,
            s.C_SecondName,
            s.C_Address,
            FORMAT(b.D_Date, 'MM.yyyy'),
            b.C_Sale_Items

        -- Объединяем, чтобы получить общую сумму по всем месяцам и услугам
        union all
        select
            s.C_Number as [Номер ЛС],
            s.C_FirstName + ' ' + s.C_SecondName as [ФИО],
            s.C_Address as [Адрес],
            'Итого' as [Месяц],
            b.C_Sale_Items as [Услуга],
            sum(b.N_Amount) as [Сумма начисления],
            sum(b.N_Amount_Rest) as [Сумма долга]
        from
            dbo.SD_Subscrs as s
        left join
            dbo.FD_Bills as b on s.LINK = b.F_Subscr
        where
            s.LINK = @F_Subscr and year(b.D_Date) = @N_Year
        group by
            s.C_Number,
            s.C_FirstName,
            s.C_SecondName,
            s.C_Address, 
            b.C_Sale_Items
        order by
            [Месяц], [Услуга];
    end
    else
    begin

        -- Запрос без детализации
        select
            s.C_Number as [Номер ЛС],
            s.C_FirstName + ' ' + s.C_SecondName as [ФИО],
            s.C_Address as [Адрес],
            format(b.D_Date, 'MM.yyyy') as [Месяц],
            sum(b.N_Amount) as [Сумма начисления],
            sum(b.N_Amount_Rest) as [Сумма долга]
        from
            dbo.SD_Subscrs as s
        left join
            dbo.FD_Bills as b on s.LINK = b.F_Subscr
        where
            s.LINK = @F_Subscr and year(b.D_Date) = @N_Year
        group by
            s.C_Number,
            s.C_FirstName,
            s.C_SecondName,
            s.C_Address,
            format(b.D_Date, 'MM.yyyy')
        
        -- Объединяем, чтобы получить общую сумму по всем месяцам
	    union all
	    select
            s.C_Number as [Номер ЛС],
            s.C_FirstName + ' ' + s.C_SecondName as [ФИО],
            s.C_Address as [Адрес],
            'Итого' as [Месяц],
            sum(b.N_Amount) as [Сумма начисления],
            sum(b.N_Amount_Rest) as [Сумма долга]
        from
            dbo.SD_Subscrs as s
        left join
            dbo.FD_Bills as b on s.LINK = b.F_Subscr
        where
            s.LINK = @F_Subscr and year(b.D_Date) = @N_Year -- Фильтруем по ЛС и году
        group by
            s.C_Number,
            s.C_FirstName,
            s.C_SecondName,
            s.C_Address
        order by 
            [Месяц];
           
    end
end;
go

/* Создаем процедуру которая будет выводить данные о расходе потребления услуг по показаниям 
на указанную дату по указанному ЛС в параметрах процедуры. */

create or alter procedure dbo.RPT_Subscrs_Quantity
	@F_Subscr int,       -- Идентификатор ЛС
	@D_Date date   -- Дата, от которой расчитывается данные о расходе потребления услуг
as
begin
	set nocount on;
	-- Создаю временную таблицу с нужными данными для расчета
	with cte_MeterReadings as (
		select
			row_number() over ( order by m.D_Date desc) as RowNum,
			C_Number as [Номер ЛС],
			s.C_FirstName + ' ' + s.C_SecondName AS [ФИО],
			d.C_Name as [ПУ],
			d.C_Serial_Number as [Серийный номер],
			d.C_Sale_Items as [Услуга],
			format(d.D_Setup_Date, 'dd.MM.yy') as [Дата Установки],
			format(d.D_Replace_Date, 'dd.MM.yy') as [Дата снятия],
			format(m.D_Date, 'dd.MM.yy') as [Дата пкз.],
			cast(round(m.N_Value, 2) as decimal(10,2)) as [Знач. пкз.],
			cast(round(t.N_Tariff, 2) as decimal (10,2)) as [Тариф]
		from 
			dbo.SD_Subscrs as s
		left join
			dbo.ED_Devices as d on d.F_Subscr = s.LINK
		left join
			dbo.ED_Meter_Readings as m on m.F_Devices = d.LINK
		left join dbo.ES_Tariff as t on t.C_Sale_Items = d.C_Sale_Items
				and
					(m.D_Date between t.D_Date_Begin and t.D_Date_End or m.D_Date > t.D_Date_Begin and t.D_Date_End is null)
		where
			s.LINK = @F_Subscr and m.D_Date <= @D_Date -- фильтруем по идентифмкатору и дате
	),
	-- создаю таблицу для получения данных по предыдущим показаниям
	cte_MeterReadings_2 as (
		select
			c1.[Номер ЛС],
			c1.ФИО,
			c1.ПУ,
			c1.[Серийный номер],
			c1.Услуга,
			c1.[Дата Установки],
			c1.[Дата снятия],
			c1.[Дата пкз.],
			c1.[Знач. пкз.],
			(select top 1 [Дата пкз.] from cte_MeterReadings where RowNum = c1.RowNum + 1) as [Пред. Дата пкз.], -- получаю данные о предыдущей дате
			(select top 1 [Знач. пкз.] from cte_MeterReadings where RowNum = c1.RowNum + 1) as [Пред. знач. пкз.], -- получаю данные о предыдущем значение
			(c1.[Знач. пкз.] - (select top 1 [Знач. пкз.] from cte_MeterReadings where RowNum = c1.RowNum + 1)) as [Расход], -- получаю данные о расходе
			c1.Тариф
		from
			cte_MeterReadings as c1
	)
	select top 1
		c2.[Номер ЛС],
		c2.ФИО,
		c2.ПУ,
		c2.[Серийный номер],
		c2.Услуга,
		c2.[Дата Установки],
		c2.[Дата снятия],
		c2.[Дата пкз.],
		c2.[Знач. пкз.],
		c2.[Пред. Дата пкз.],
		c2.[Пред. знач. пкз.],
		c2.[Расход],
		-- получаю средний расход за 12 месяцев
		cast(((select sum([Расход])/12 
		from cte_MeterReadings_2 
		where [Дата пкз.] <= @D_Date 
		and [Дата пкз.] >= DATEADD(MONTH, -12, @D_Date)
		and [Расход] is not null)) as decimal (10,2)) as [Средний расход],
		c2.Тариф,
		cast((round((c2.[Расход] * c2.Тариф),2)) as decimal(10,2)) as [Сумма]
	from cte_MeterReadings_2 as c2
end;