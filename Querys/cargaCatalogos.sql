--Tabla para guardar el xml
	DROP TABLE IF EXISTS XMLwithOpenXML
	CREATE TABLE XMLwithOpenXML(Id INT IDENTITY PRIMARY KEY, XMLData XML)

	--Se abre el archivo y se inserta el contenido en la tabla
    INSERT INTO XMLwithOpenXML(XMLData)
    SELECT CONVERT(XML, BulkColumn) AS BulkColumn
    FROM OPENROWSET(BULK 'C:\Users\Allison\Documents\Semestre IV\Bases I\Catalogo-Tarea-3.xml', SINGLE_BLOB) AS x;

	--Para mostrar el xml cargado correctamente
    SELECT * FROM XMLwithOpenXML

	--Para poder parsear el xml
    DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX)
    SELECT @XML = XMLData FROM XMLwithOpenXML
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML

---------------PARA TIPO_DOC_ID---------------
	--Crea una tabla temporal
	DECLARE @Temporal TABLE(Nombre nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @Temporal (Nombre)
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/TipoDoc/TipoDocuIdentidad')
    WITH (Nombre NCHAR(30))


INSERT INTO dbo.TipoDocIdentidad(Nombre) (SELECT Nombre FROM @Temporal)

---------------PARA TIPO_MONEDA---------------

--Crea una tabla temporal
	DECLARE @TemporalMoneda TABLE(Nombre nchar(30), Simbolo nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @TemporalMoneda
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/TipoMoneda/TipoMoneda')
    WITH (Nombre NCHAR(30),
		  Simbolo NCHAR(30))


INSERT INTO dbo.TipoMoneda(Nombre, Simbolo) (SELECT * FROM @TemporalMoneda)


---------------PARA PARENTESCOS---------------

--Crea una tabla temporal
	DECLARE @TemporalParentesco TABLE(Nombre nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @TemporalParentesco
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/Parentezcos/Parentezco')
    WITH (Nombre NCHAR(30))


INSERT INTO dbo.Parentesco(Nombre) (SELECT * FROM @TemporalParentesco)

---------------PARA TIPO_CUENTA_AHORROS---------------

--Crea una tabla temporal
	DROP TABLE IF EXISTS #TemporalTipoCA
	CREATE TABLE #TemporalTipoCA(Nombre nchar(30), 
							     TipoMonedaID nchar(30), 
								 SaldoMinimo nchar(30), 
								 MultaSaldoMinimo nchar(30), 
								 CargoAnual nchar(30), 
								 MaxOPCajeroHumano nchar(30),
								 MaxOPCajeroAutomatico nchar(30), 
								 ComisionOPCajeroHumano nchar(30), 
								 ComisionOPCajeroAutomatico nchar(30), 
								 TasaInteres nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO #TemporalTipoCA
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/Tipo_Cuenta_Ahorro/TipoCuentaAhorro')
    WITH (Nombre NCHAR(30),
		  IdTipoMoneda NCHAR(30),
		  SaldoMinimo NCHAR(30),
		  MultaSaldoMin NCHAR (30),
		  CargoMensual NCHAR(30),
		  NumRetiroHumano NCHAR (30),
		  NumRetirosAutomatico NCHAR(30),
		  ComisionHumano NCHAR(30),
		  ComisionAutomatico NCHAR(30),
		  Interes NCHAR(30))


	--Cambia el tipo de dato de toda la columna
		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN TipoMonedaID int

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN SaldoMinimo float

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN MultaSaldoMinimo float

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN CargoAnual int

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN MaxOPCajeroHumano int

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN MaxOPCajeroAutomatico int

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN ComisionOPCajeroHumano int

		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN ComisionOPCajeroAutomatico int


		ALTER TABLE #TemporalTipoCA
		ALTER COLUMN TasaInteres int

INSERT INTO dbo.TipoCuentaAhorro(Nombre, 
								 TipoMonedaID, 
								 SaldoMinimo, 
								 MultaSaldoMinimo, 
								 CargoAnual, 
								 MaxOPCajeroHumano, 
								 MaxOPCajeroAutomatico, 
								 ComisionOPCajeroHumano,
								 ComisionOPCajeroAutomatico, 
								 TasaInteres) 

						(SELECT Nombre,
								TipoMonedaID, 
								SaldoMinimo, 
								MultaSaldoMinimo, 
								CargoAnual, 
								MaxOPCajeroHumano, 
								MaxOPCajeroAutomatico, 
								ComisionOPCajeroHumano, 
								ComisionOPCajeroAutomatico, 
								TasaInteres FROM #TemporalTipoCA)

---------------PARA TIPO MOVIMIENTO CA---------------

--Crea una tabla temporal
	DECLARE @TemporalTipoMov TABLE(Nombre nchar(30), Tipo nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @TemporalTipoMov
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/TipoMovimientos/TipoMovimiento')
    WITH (Nombre NCHAR(30),
		  Tipo NCHAR(30))

   INSERT INTO dbo.TipoMovimientoCA(Nombre, TipoOperacion)
   SELECT Nombre, Tipo FROM @TemporalTipoMov

---------------PARA TIPO MOVIMIENTO CO---------------

--Crea una tabla temporal
	DECLARE @TipoMovCO TABLE(Nombre nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @TipoMovCO
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/TiposMovimientoCuentaAhorro/Tipo_Movimiento')
    WITH (Nombre NCHAR(30))

   INSERT INTO dbo.TipoMovimientoCO(Nombre)
   SELECT Nombre FROM @TipoMovCO

---------------PARA TIPO Evento---------------

	--Crea una tabla temporal
	DECLARE @tipoEvento TABLE(Nombre nchar(30))

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO @tipoEvento
    SELECT *
    FROM OPENXML(@hDoc, 'Catalogos/TiposEvento/TipoEvento')
    WITH (Nombre NCHAR(30))

   INSERT INTO dbo.TipoEvento(Nombre)
   SELECT Nombre FROM @tipoEvento