--Tabla para guardar el xml
	DROP TABLE IF EXISTS XMLwithOpenXML
	CREATE TABLE XMLwithOpenXML(Id INT IDENTITY PRIMARY KEY, XMLData XML)

	--Se abre el archivo y se inserta el contenido en la tabla
    INSERT INTO XMLwithOpenXML(XMLData)
    SELECT CONVERT(XML, BulkColumn) AS BulkColumn
    FROM OPENROWSET(BULK 'C:\Users\Allison\Documents\Semestre IV\Bases I\Datos-Tarea3.xml', SINGLE_BLOB) AS x;

	--Para mostrar el xml cargado correctamente
    SELECT * FROM XMLwithOpenXML

	--Para poder parsear el xml
    DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX)
    SELECT @XML = XMLData FROM XMLwithOpenXML
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML

---------------PARA SACAR LAS FECHAS---------------
	--Crea una tabla temporal
	DROP TABLE IF EXISTS #Temporal
	CREATE TABLE #Temporal(ID INT IDENTITY, Fecha date)

	--Parsea el xml y guarda los datos en la tabla temporal
	INSERT INTO #Temporal
    SELECT *
    FROM OPENXML(@hDoc, 'Operaciones/FechaOperacion')
    WITH (Fecha date)

	

	-----RECORREMOS LAS FECHAS CON UN WHILE-----
	DECLARE @LO AS INT, --contador del while
			@HI AS INT, --tope
			@actual as date --esta es la fecha sobre la que estamos iterando

	--se definen los valores iniciales
	SET @LO = 1
	SELECT @HI = COUNT (*) FROM #Temporal 
	SELECT @actual = Fecha from #Temporal WHERE ID = 1

	WHILE @LO <= @HI
	BEGIN 
		
		--Hacemos otro while para recorrer todas las cuentas objetivo
		DECLARE @contador as int, @tope as int
		SET @contador = 1
		SELECT @tope = COUNT (*) FROM dbo.CuentaObjetivo

		WHILE @contador <= @tope
		BEGIN
			--se saca la fecha fin del ahorro
			DECLARE @fechaFin as date
			SELECT @fechaFin = FechaFin from dbo.CuentaObjetivo WHERE ID = @contador

			--si la fecha fin coincide con el día actual entonces se procesa el cierre del ahorro
			IF @fechaFin = @actual
				--aqui se procesa todo
			ELSE
				--aqui se hacen los calculos de intereses del día

			--Se aumenta el contador del while de cuentas de ahorro
			SET @contador = @contador +1
		END


		--se le suma un dia a la fecha actual para la siguiente iteración
		SELECT @actual = DATEADD(DAY, 1, @actual)
		SET @LO = @LO + 1
	END 