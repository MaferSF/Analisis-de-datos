--Caso 1:
--El equipo de ventas quiere identificar el canal más fuerte del último trimestre del 2019.
--Instrucción: Muestra el canal, trimestre y su total de ventas.
--1.Renombrar la columnda Channel_Key para conectar con la tablas Sales. Renombrar la columna DateKey para conectar con la tabla
--Date.
Exec sp_rename 'dbo.Channel.Channel_Key', 'channelKey';
Exec sp_rename 'dbo.Sales.DateKey', 'Fecha';
--JOIN
select
	sum(s.SalesAmount) as VentasTotales,
	d.Trimestre as Trimestre,
	ch.ChannelName as Canal
from dbo.Sales  s
inner join dbo.Channel ch on s.channelKey = ch.channelKey
inner join dbo.Date d on s.Fecha = d.Fecha
where d.NumeroTrimestre = 4 AND d.Año = 2019
Group by
	d.Trimestre,
	ch.ChannelName


--Caso 2:
--Finanzas quiere identificar los productos con mayor margen unitario.
--Instrucción: Muestra los 10 productos con mayor margen (UnitPrice - UnitCost).
Exec sp_rename 'dbo.Product.Product_Key', 'ProductKey';
select Top 10
	p.ProductName as Producto,
	(s.UnitPrice - s.UnitCost) as Margen
from dbo.Sales s
Inner join dbo.Product p on s.ProductKey = p.ProductKey
group by
	p.ProductName,
	(s.UnitPrice - s.UnitCost)
order by Margen desc

--Caso 3:
--Dirección general solicita una visualización de ventas mes a mes.
--Instrucción: Total de ventas agrupadas por mes y año.

select
	s.ProductKey as IdProducto,
	sum(s.SalesAmount) as Ventas,
	d.Mes as Mes,
	d.Año as Año
from dbo.Sales s
inner join dbo.Date d on s.Fecha = d.Fecha
where d.Año = 2018
Group by
	s.ProductKey,
	d.Mes,
	d.Año
Order by
	d.Mes ASC

--Caso4:
--Análisis geográfico de desempeño de ventas.
--Instrucción: Total de ventas por país (RegionCountryName)

Exec sp_rename 'dbo.Stores.Store_Key', 'channelKey';
Exec sp_rename 'dbo.Stores.Geography_Key', 'GeographyKey';

select
	g.ContinentName as Continente,
	g.RegionCountryName as Pais,
	sum(s.SalesAmount) as VentasTotales
from dbo.sales s
inner join dbo.stores st on s.channelKey = s.channelKey
inner join dbo.geography g on st.GeographyKey = g.geographyKey
group by
	g.RegionCountryName,
	g.ContinentName 

--Caso 5:
--Evaluar cuánto se dejó de ganar por descuentos.
--Instrucción: Total de DiscountAmount por año.

select
	YEAR(d.Fecha) as Año,
	SUM(s.DiscountAmount) as Descuento
from dbo.Sales s
inner join dbo.date d on s.Fecha = d.Fecha
group by
	YEAR(d.Fecha)

--Caso 6:
--Operaciones revisará tiendas con menores ventas de acuerdo con rangos personalizados de fecha.
--Instrucción: Mostrar las 5 mejores y 5 peores tiendas, Usar Procedimientos almacenados.
--¿Cómo trabajarlo?
--JOIN con Date y Stores.
--Filtro de fecha.
--Agrupar por tienda y ordenar ascendente.

exec sp_rename 'dbo.stores.Store_Key','StoreKey';
select*from dbo.date
select*from dbo.sales

create or alter procedure sp_Tiendas
	@FechaInicio DATE,
    @FechaFin DATE

As
Begin
--peores tiendad
		Select Top 5
			st.storename as NombreTienda,
			sum(s.salesamount) as VentasTotales
		from dbo.sales s
		inner join dbo.stores st on s.StoreKey = st.StoreKey
		inner join dbo.date d on s.Fecha = d.Fecha
		where
			d.Fecha BETWEEN @FechaInicio AND @FechaFin
		group by
			st.storename
		Order by
			VentasTotales ASC
--mejores tiendas
		Select Top 5
			st.storename as NombreTienda,
			sum(s.salesamount) as VentasTotales
		from dbo.sales s
		inner join dbo.stores st on s.StoreKey = st.StoreKey
		inner join dbo.date d on s.Fecha = d.Fecha
		where
			d.Fecha BETWEEN @FechaInicio AND @FechaFin
		group by
			st.storename
		Order by
			VentasTotales DESC

End

exec sp_Tiendas
	@FechaInicio = '2018-01-01',
    @FechaFin = '2018-12-30'

--Caso 7:
--Se busca saber qué categoría vendió más en 2019 en función a la cantidad y monto.
--Instrucción: Total de ventas y unidades por ProductCategoryName. Utilizar Procedimientos almacenados.
--¿Cómo trabajarlo?
--JOIN entre Sales, Product, Product_SubCategory, Product_Category.
--Filtro por año.
--GROUP BY con agregados.
Exec sp_rename 'dbo.Product.Product_Key', 'ProductKey';

create or alter procedure CASO7
	@topN Int,
	@criterio1 nvarchar (50)
As
Begin
select
	Top(@topN)
	pc.ProductCategoryName as CategoriaProducto,
	sum(s.salesquantity) as Cantidad,
	sum(s.salesquantity*s.unitprice) as Monto
from dbo.sales s
inner join dbo.product p on s.ProductKey = p.ProductKey
inner join dbo.Product_SubCategory ps on  p.productsubcategorykey = ps.productsubcategorykey
inner join dbo.product_Category pc on ps.ProductCategoryKey = pc.ProductCategoryKey
where 
	s.DateKey = '2019'
group by
	pc.ProductCategoryName
order by
	CASE
		WHEN @criterio1 = 'Cantidad' then sum(s.salesquantity)
		WHEN @criterio1 = 'Monto' then sum(s.salesquantity*s.unitprice)
	ELSE sum(s.salesquantity)
	END ASC
End

Exec CASO7

	@topN = 8,
	@criterio1 = 'Cantidad'


--Caso 8:
--Finanzas desea ver cómo varía el margen mes a mes.
--Instrucción: Muestra el margen (SalesAmount - TotalCost) por mes de 2023.
--Trabajar con acumulados mensuales.
--¿Cómo trabajarlo?
--JOIN con Date.
--Calcular diferencia SalesAmount - TotalCost.
--Agrupar por NumeroMes y Año.
Exec sp_rename 'dbo.Sales.DateKey', 'Fecha';

select
	 Month(d.Fecha) as Mes,
	 Year(d.Fecha) as Año, 
	 sum(s.SalesAmount - s.TotalCost) as Margen
from dbo.sales s
inner join dbo.date d on s.Fecha = d.Fecha
where
	YEAR(d.Fecha) = '2018'
group by
	Month(d.Fecha),
	Year(d.Fecha)

	



