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
		DECLARE @contador as int
		DECLARE @tope as int
		SET @contador = 1
		SELECT @tope = COUNT (*) FROM dbo.CuentaObjetivo
		
		WHILE @contador <= @tope
		BEGIN

			--se saca la fecha fin del ahorro
			DECLARE @fechaFin as date
			SELECT @fechaFin = FechaFin from dbo.CuentaObjetivo WHERE ID = @contador

			--Proceso de acumulaci�n de intereses
			DECLARE @fechaInicio as date 
			SELECT @fechaInicio = FechaInicio FROM dbo.CuentaObjetivo WHERE ID = @contador

			IF @actual BETWEEN @fechaInicio AND @fechaFin
			BEGIN
				DECLARE @cantidadMeses as int
				SELECT @cantidadMeses = DATEDIFF(MONTH, @fechaInicio, @fechaFin)

				DECLARE @porcentajeInteres as float
				SET @porcentajeInteres = @cantidadMeses * 0.5

				--Se calcula el inter�s diario
				SET @porcentajeInteres = @porcentajeInteres / 365
			
				--Se calcula el inter�s ganado
				DECLARE @interesGanado as float, @saldoCO as float, @interesAnterior as float
				SELECT @interesAnterior = InteresAcum FROM CuentaObjetivo WHERE ID = @contador
				SELECT @saldoCO = Saldo FROM CuentaObjetivo WHERE ID = @contador
				SET @interesGanado = (@saldoCO * @porcentajeInteres) / 100
			

				--Se le aplica el inter�s ganado a la cuenta objetivo
				UPDATE dbo.CuentaObjetivo
				SET InteresAcum = InteresAcum + @interesGanado
				WHERE ID = @contador
			
				--Creamos el movimiento de la cuenta movCOInteres--
				INSERT INTO dbo.MovCOInteres (CuentaObjetivoID, Fecha, Monto, NuevoInteresAcum)
				VALUES (@contador, @actual, @interesGanado, @interesAnterior+@interesGanado)


				--PROCESAR REDENCI�N DE CO-- 
				IF @fechaFin = @actual
				BEGIN
					--***Redenci�n de intereses***--
				
					--sacamos el total de intereses acumulados
					DECLARE @totalInteres as float
					SELECT @totalInteres = InteresAcum FROM dbo.CuentaObjetivo WHERE ID = @contador
				

					UPDATE dbo.CuentaObjetivo
					SET InteresAcum = 0.0
					WHERE ID = @contador

					--Creamos el movimiento en la tabla MovCOInteres
					INSERT INTO dbo.MovCOInteres(CuentaObjetivoID, Fecha, Monto, NuevoInteresAcum)
					VALUES(@contador, @actual, @totalInteres, 0)

					--Creamos el movimiento en la tabla MovCo
					INSERT INTO dbo.MovCO(TipoMovCOID, CuentaObjetivoID, Fecha, Monto, Valido)
					VALUES(2, @contador, @actual, @totalInteres, 1)

					----Sumamos el inter�s acumulado al saldo de la CO
					UPDATE dbo.CuentaObjetivo
					SET Saldo = Saldo + @totalInteres
					WHERE ID = @contador

					----***Redenci�n de CO***--
					DECLARE @totalAhorrado as float
					SELECT @totalAhorrado = Saldo FROM dbo.CuentaObjetivo
					WHERE ID = @contador
					

					UPDATE dbo.CuentaObjetivo
					SET Saldo = 0
					WHERE ID = @contador

					--Buscamos el id de la Cuenta de Ahorros
					DECLARE @CuentaAhorrosID as int
					SELECT @CuentaAhorrosID = CuentadeAhorroID FROM dbo.CuentaObjetivo WHERE ID = @contador 

					--sumamos el ahorro al saldo de la cuenta principal
					UPDATE dbo.CuentadeAhorro
					SET Saldo = Saldo + @totalAhorrado
					WHERE NumerodeCuenta = @CuentaAhorrosID
				   
					--Tomamos el saldo de la CA
					DECLARE @SaldoCuentaAhorros as float
					SELECT @SaldoCuentaAhorros = Saldo FROM dbo.CuentadeAhorro WHERE NumerodeCuenta = @CuentaAhorrosID
					
					--Registramos el movimiento en la tabla de MovimientoCA
					INSERT INTO dbo.MovimientoCA(TipoMovCAID, numCuentaID, Fecha, Monto, NuevoSaldo, Descripcion, Visible)
					VALUES(4, @CuentaAhorrosID, @actual, @totalAhorrado, @SaldoCuentaAhorros, 'Ahorro de Cuenta Objetivo', 1)

				END	
				ELSE
					--aqui se pregunta si es el d�a del ahorro del mes 
					DECLARE @diaAhorro as int
					SELECT @diaAhorro = DiasDeposito FROM CuentaObjetivo WHERE ID = @contador

					--sacamos el d�a de la fecha actual
					DECLARE @diaActual as int
					SELECT @diaActual = DAY(@actual)

					IF @diaAhorro = @diaActual 
					BEGIN
						--PROCESAR DEP�SITOS EN LA CO--
					
						--primero se corrobora que la cuenta de ahorro tiene saldo suficiente para debitar el monto
						DECLARE @SaldoRestante as float --aqui se guarda el restante de la CA despu�s de debitar el monto del ahorro
						DECLARE @montoAhorro as float
						DECLARE @saldoCA as float
						DECLARE @numCuenta as int

						SELECT @montoAhorro = Cuota FROM CuentaObjetivo WHERE ID = @contador
						SELECT @numCuenta = CuentadeAhorroID FROM CuentaObjetivo WHERE ID = @contador

						SELECT @saldoCA = Saldo FROM CuentadeAhorro WHERE NumerodeCuenta = @numCuenta

						SET @SaldoRestante = @saldoCA - @montoAhorro
					
						--se hace el rebajo en la CA
						IF @SaldoRestante >= 0 
						BEGIN
							UPDATE dbo.CuentadeAhorro
							SET Saldo = @SaldoRestante
							WHERE NumerodeCuenta = @numCuenta
						
							--creamos un nuevo movimiento para reflejar el debito en la CA
							INSERT INTO dbo.MovimientoCA (TipoMovCAID, 
														  numCuentaID, 
														  Fecha, 
														  Monto, 
														  NuevoSaldo, 
														  Descripcion, 
														  Visible)

							VALUES(3, @numCuenta, @actual, @montoAhorro, @SaldoRestante, 'Ahorro', 1)


							--creamos un nuevo movimiento para reflejar el cr�dito en la CO	
							INSERT INTO dbo.MovCO (TipoMovCOID, 
												   CuentaObjetivoID,
												   Fecha, 
												   Monto,
												   Valido) 

							VALUES (1, @contador, @actual, @montoAhorro, 1)

							--Se hace el incremento en el saldo la CO
							UPDATE dbo.CuentaObjetivo
							SET Saldo = Saldo + @montoAhorro
							WHERE ID = @contador
					 END
					 ELSE
					--creamos un nuevo movimiento para reflejar el cr�dito en la CO	
							INSERT INTO dbo.MovCO (TipoMovCOID, 
												   CuentaObjetivoID,
												   Fecha, 
												   Monto,
												   Valido) 

							VALUES (1, @contador, @actual, @montoAhorro, 0)

							

				END
			
			END
			--Se aumenta el contador del while de cuentas de ahorro
			SET @contador = @contador +1
		END


		--se le suma un dia a la fecha actual para la siguiente iteraci�n
		SELECT @actual = DATEADD(DAY, 1, @actual)
		SET @LO = @LO + 1
	END  