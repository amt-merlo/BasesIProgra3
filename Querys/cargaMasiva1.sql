--Se abre el archivo y se inserta el contenido en la tabla
    INSERT INTO XMLwithOpenXML(XMLData)
    SELECT CONVERT(XML, BulkColumn) AS BulkColumn
    FROM OPENROWSET(BULK 'C:\Users\Allison\Documents\Semestre IV\Bases I\Datos-Tarea3.xml', SINGLE_BLOB) AS x;


	--Para poder parsear el xml
    DECLARE @XML AS XML, @hDoc AS INT, @SQL NVARCHAR (MAX)
    SELECT @XML = XMLData FROM XMLwithOpenXML
    EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML

	
--Intento #1--

--Para parsear el fecha=x
DECLARE @Fecha varchar(30)
SET @Fecha = '08-01-2020'

--Selecciona todos los subnodos del fecha x

---------------------------PARA PARSEAR PERSONAS---------------------------
DECLARE @Personas AS XML
SELECT @Personas =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//Persona')
SELECT @Personas 

--Tabla variable
	 DECLARE @TablaPersonas TABLE(TipoDocuIdentidad int, 
								  Nombre nchar(30), 
								  ValorDocumentoIdentidad nchar(30), 
								  FechaNacimiento date, 
								  Email nchar(30), 
								  Telefono1 int, 
								  Telefono2 int)
	
	 DECLARE @TipoDocuIdentidad TABLE(ID INT IDENTITY,TipoID int)
	 DECLARE @Nombre TABLE(ID INT IDENTITY,nombre nchar(30))
	 DECLARE @ValorDocumentoIdentidad TABLE(ID INT IDENTITY,valorID int)
	 DECLARE @FechaNacimiento TABLE(ID INT IDENTITY,fecha date)
	 DECLARE @Email TABLE(ID INT IDENTITY, email nchar(30))
	 DECLARE @Telefono1 TABLE(ID INT IDENTITY, telefono1 int)
	 DECLARE @Telefono2 TABLE(ID INT IDENTITY, telefono2 int)


	 --Insertar en la tabla 
	 INSERT INTO @TipoDocuIdentidad (TipoID)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Personas.nodes('/Persona/@TipoDocuIdentidad') xmlData(A)

	 INSERT INTO @Nombre (nombre)
		SELECT 	xmlData.A.value('.', 'nchar(30)') AS CodigoCuenta 
		FROM	@Personas.nodes('/Persona/@Nombre') xmlData(A)

	 INSERT INTO @ValorDocumentoIdentidad (valorID)
		SELECT 	xmlData.A.value('.', 'int') AS Monto 
		FROM	@Personas.nodes('/Persona/@ValorDocumentoIdentidad') xmlData(A)

	 INSERT INTO @FechaNacimiento (fecha)
		SELECT 	xmlData.A.value('.', 'date') AS Descripcion 
		FROM	@Personas.nodes('/Persona/@FechaNacimiento') xmlData(A)

	INSERT INTO @Email (email)
		SELECT 	xmlData.A.value('.', 'nchar(30)') AS Descripcion 
		FROM	@Personas.nodes('/Persona/@Email') xmlData(A)

	INSERT INTO @Telefono1 (telefono1)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@Personas.nodes('/Persona/@Telefono1') xmlData(A)

	INSERT INTO @Telefono2 (telefono2)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@Personas.nodes('/Persona/@Telefono2') xmlData(A)

	INSERT INTO @TablaPersonas(TipoDocuIdentidad, Nombre, ValorDocumentoIdentidad, Email, FechaNacimiento, Telefono1, Telefono2)
	SELECT T.TipoID, N.nombre, V.valorID, E.email, Fecha.fecha, T1.telefono1, T2.telefono2
	from @TipoDocuIdentidad as T
	LEFT JOIN @Nombre as N on N.ID = T.ID
	LEFT JOIN @ValorDocumentoIdentidad as V on V.ID = T.ID
	LEFT JOIN @Email as E on E.ID = T.ID
	LEFT JOIN @FechaNacimiento as Fecha on Fecha.ID = T.ID
	LEFT JOIN @Telefono1 as T1 on T1.ID = T.ID
	LEFT JOIN @Telefono2 as T2 on T2.ID = T.ID
	
	INSERT INTO dbo.Persona(TipoDocID, 
						    Nombre, 
							ValorDocIdentidad, 
							FechaNacimiento, 
							email, 
							Telefono1, 
							Telefono2)

					SELECT TipoDocuIdentidad, 
						   Nombre, 
						   ValorDocumentoIdentidad, 
						   FechaNacimiento, 
						   Email, 
						   Telefono1, 
						   Telefono2 FROM @TablaPersonas

	---------------------------PARA PARSEAR CUENTAS---------------------------
	DECLARE @Cuentas AS XML
	SELECT @Cuentas =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//Cuenta')

	--Crear tabla para todos los datos
	DROP TABLE IF EXISTS #TablaCuentas
	CREATE TABLE #TablaCuentas (TipoCuentaID int, 
								NumeroCuenta int, 
								ValorDocID int, 
								FechaConstitucion date, 
								Saldo float)

	--Tabla variable para ingresar los datos individuales
	DROP TABLE IF EXISTS #ValorDocID, #TipoCuentaID, #NumeroCuenta, #FechaConstitucion, #Saldo
	CREATE TABLE #ValorDocID (ID INT IDENTITY, valorDocID int)
	CREATE TABLE #TipoCuentaID (ID INT IDENTITY, TipoCuentaID int)
	CREATE TABLE #NumeroCuenta (ID INT IDENTITY, NumCuenta int)
	CREATE TABLE #FechaConstitucion (ID INT IDENTITY, FechaConstitucion date)
	CREATE TABLE #Saldo (ID INT IDENTITY, Saldo float)

	

	ALTER TABLE #TablaCuentas 
	ADD CONSTRAINT modificar_saldo3
	DEFAULT 0.0 FOR Saldo

	INSERT INTO #ValorDocID (valorDocID)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@Cuentas.nodes('/Cuenta/@ValorDocumentoIdentidadDelCliente') xmlData(A)

	INSERT INTO #TipoCuentaID (TipoCuentaID)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@Cuentas.nodes('/Cuenta/@TipoCuentaId') xmlData(A)

	INSERT INTO #NumeroCuenta (NumCuenta)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@Cuentas.nodes('/Cuenta/@NumeroCuenta') xmlData(A)

	INSERT INTO #TablaCuentas(TipoCuentaID, 
							  NumeroCuenta, 
							  ValorDocID)

	SELECT T.TipoCuentaID, N.NumCuenta, V.ValorDocID
	FROM #TipoCuentaID AS T
	LEFT JOIN #NumeroCuenta AS N ON N.ID = T.ID
	LEFT JOIN #ValorDocID AS V ON V.ID = T.ID

	 UPDATE #TablaCuentas
	 SET FechaConstitucion = @Fecha
	
	--Aquí se hace el mapeo con el ID de la persona--


	INSERT INTO dbo.CuentadeAhorro(TipoCuentaAhorroID, 
								   NumerodeCuenta, 
								   ValorDocIdentidadCliente, 
								   FechaConstitucion,
								   Saldo) --corregir ID persona

							SELECT TipoCuentaId, 
								   NumeroCuenta, 
								   ValorDocID, 
								   FechaConstitucion, 
								   Saldo FROM #TablaCuentas

	---------------------------PARA PARSEAR CUENTAS OBJETIVO---------------------------
	DECLARE @CuentasObj AS XML
	SELECT @CuentasObj =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//CuentaAhorro')

	--Crear tabla para todos los datos
	DROP TABLE IF EXISTS #TablaCuentasObj
	CREATE TABLE #TablaCuentasObj (numeroCA int, 
								   NumeroCuenta int, 
								   monto float, 
								   diaAhorro int,
								   fechaInicio date,
								   fechaFinal date,
								   objetivo nchar(60),
								   saldo float,
								   interesAcum float,
								   InsertedAt date)

	--Tabla variable para ingresar los datos individuales
	DROP TABLE IF EXISTS #numeroCA, #NumCuenta, #monto, #diaAhorro, #fechaFinal, #objetivo
	CREATE TABLE #numeroCA (ID INT IDENTITY, numeroCA int)
	CREATE TABLE #NumCuenta (ID INT IDENTITY, NumeroCuenta int)
	CREATE TABLE #monto (ID INT IDENTITY, monto float)
	CREATE TABLE #diaAhorro (ID INT IDENTITY, diaAhorro int)
	CREATE TABLE #fechaFinal (ID INT IDENTITY, fechaFinal date)
	CREATE TABLE #objetivo (ID INT IDENTITY, objetivo nchar(60))

	

	ALTER TABLE #TablaCuentasObj 
	ADD CONSTRAINT modificar_saldoCO
	DEFAULT 0.0 FOR Saldo

	INSERT INTO #numeroCA (numeroCA)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@NumeroCuentaPrimaria') xmlData(A)

	INSERT INTO #NumCuenta (NumeroCuenta)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@NumeroCuentaAhorro') xmlData(A)

	INSERT INTO #monto (monto)
		SELECT 	xmlData.A.value('.', 'float') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@MontoAhorro') xmlData(A)

	INSERT INTO #diaAhorro (diaAhorro)
		SELECT 	xmlData.A.value('.', 'int') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@DiaAhorro') xmlData(A)

	INSERT INTO #fechaFinal (fechaFinal)
		SELECT 	xmlData.A.value('.', 'date') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@FechaFinal') xmlData(A)

	INSERT INTO #objetivo (objetivo)
		SELECT 	xmlData.A.value('.', 'nchar(60)') AS Descripcion 
		FROM	@CuentasObj.nodes('/CuentaAhorro/@Descripcion') xmlData(A)

	INSERT INTO #TablaCuentasObj(numeroCA, 
							  NumeroCuenta, 
							  monto,
							  diaAhorro,
							  fechaFinal,
							  objetivo)

	SELECT T.numeroCA, N.NumeroCuenta, M.monto, D.diaAhorro, F.fechaFinal, O.objetivo
	FROM #numeroCA AS T
	LEFT JOIN #NumCuenta AS N ON N.ID = T.ID
	LEFT JOIN #monto AS M ON M.ID = T.ID
	LEFT JOIN #diaAhorro AS D ON D.ID = T.ID
	LEFT JOIN #fechaFinal AS F ON F.ID = T.ID
	LEFT JOIN #objetivo AS O ON O.ID = T.ID

	 UPDATE #TablaCuentasObj
	 SET fechaInicio = @Fecha

	 UPDATE #TablaCuentasObj
	 SET InteresAcum = 0.0

	 UPDATE #TablaCuentasObj
	 SET InsertedAt = @Fecha
	

	INSERT INTO dbo.CuentaObjetivo(CuentadeAhorroID, 
								   numCuenta,
								   FechaInicio, 
								   FechaFin, 
								   Cuota,
								   Objetivo,
								   Saldo,
								   InteresAcum,
								   DiasDeposito,
								   InsertedAt) --corregir ID persona

							SELECT numeroCA, 
								   NumeroCuenta,
								   fechaInicio, 
								   fechaFinal, 
								   monto, 
								   objetivo,
								   saldo,
								   InteresAcum,
								   diaAhorro,
								   InsertedAt FROM #TablaCuentasObj
							

	---------------------------PARA PARSEAR Beneficiarios---------------------------
	DECLARE @Beneficiarios AS XML
	SELECT @Beneficiarios =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//Beneficiario')

	--Tablas variable 
	DROP TABLE IF EXISTS #TablaBeneficiarios
	CREATE TABLE #TablaBeneficiarios(NumeroCuenta int, 
									 ValorDocID int, 
									 ParentescoID int, 
									 Porcentaje int,
									 InsertedAt date)

	DECLARE @NumeroCuenta TABLE (ID INT IDENTITY, numCuenta int)
	DECLARE @ValorDocID TABLE (ID INT IDENTITY, valorDocID int)
	DECLARE @ParentescoID TABLE (ID INT IDENTITY, parentescoID int)
	DECLARE @Porcentaje TABLE (ID INT IDENTITY, porcentaje int)
	
	INSERT INTO @NumeroCuenta (numCuenta)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Beneficiarios.nodes('/Beneficiario/@NumeroCuenta') xmlData(A)

	INSERT INTO @ValorDocID (valorDocID)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Beneficiarios.nodes('/Beneficiario/@ValorDocumentoIdentidadBeneficiario') xmlData(A)

	INSERT INTO @ParentescoID (parentescoID)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Beneficiarios.nodes('/Beneficiario/@ParentezcoId') xmlData(A)

	INSERT INTO @Porcentaje (porcentaje)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Beneficiarios.nodes('/Beneficiario/@Porcentaje') xmlData(A)

	INSERT INTO #TablaBeneficiarios (NumeroCuenta, 
									 ValorDocID, 
									 ParentescoID, 
									 Porcentaje)

	SELECT N.numCuenta, V.valorDocID, P.parentescoID, P2.Porcentaje
	From @NumeroCuenta AS N
	LEFT JOIN @ValorDocID AS V ON V.ID = N.ID
	LEFT JOIN @ParentescoID AS P ON P.ID = N.ID
	LEFT JOIN @Porcentaje AS P2 ON P2.ID = N.ID

	UPDATE #TablaBeneficiarios
	SET InsertedAt = @Fecha

	INSERT INTO dbo.Beneficiario(CuentadeAhorroID, 
								 PersonaID, 
								 ParentescoID, 
								 Porcentaje,
								 InsertedAt)

	SELECT NumeroCuenta, 
		   ValorDocID, 
		   ParentescoID, 
		   Porcentaje,
		   InsertedAt FROM #TablaBeneficiarios


	---------------------------PARA PARSEAR USUARIOS---------------------------
	DECLARE @Usuarios AS XML
	SELECT @Usuarios =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//Usuario')
	

	--Tabla variable
		 DECLARE @TablaUsuarios TABLE(Usuario nchar(30), 
									  Pass nchar(30), 
									  ValorDocumentoIdentidad nchar(30), 
									  EsAdministrador bit)

	 DECLARE @Usuario TABLE(ID INT IDENTITY, usuario nchar(60))
	 DECLARE @Pass TABLE(ID INT IDENTITY, pass nchar(60))
	 DECLARE @ValorDocumentoIdentidadUser TABLE(ID INT IDENTITY,valorID int)
	 DECLARE @EsAdministrador TABLE(ID INT IDENTITY, esAdmin bit)

	 --Insertar en la tabla 
	 INSERT INTO @Usuario (Usuario)
		SELECT 	xmlData.A.value('.', 'nchar(60)') AS Usuario 
		FROM	@Usuarios.nodes('/Usuario/@User') xmlData(A)

	 INSERT INTO @Pass (pass)
		SELECT 	xmlData.A.value('.', 'nchar(60)') AS Pass 
		FROM	@Usuarios.nodes('/Usuario/@Pass') xmlData(A)

	 INSERT INTO @ValorDocumentoIdentidadUser (valorID)
		SELECT 	xmlData.A.value('.', 'int') AS valorID 
		FROM	@Usuarios.nodes('/Usuario/@ValorDocumentoIdentidad') xmlData(A)

	 INSERT INTO @EsAdministrador (esAdmin)
		SELECT 	xmlData.A.value('.', 'bit') AS EsAdmin 
		FROM	@Usuarios.nodes('/Usuario/@EsAdministrador') xmlData(A)


	INSERT INTO @TablaUsuarios(Usuario, Pass, ValorDocumentoIdentidad, EsAdministrador)
	SELECT U.Usuario, P.pass, V.valorID, A.esAdmin
	FROM @Usuario as U 
	LEFT JOIN @Pass AS P ON P.ID = U.ID
	LEFT JOIN @ValorDocumentoIdentidadUser AS V ON V.ID = U.ID
	LEFT JOIN @EsAdministrador AS A ON A.ID = U.ID


	INSERT INTO dbo.Usuario(ValorDocumentoIdentidadID, 
							Username, 
							Pass, 
							EsAdministrador)

	SELECT ValorDocumentoIdentidad, 
		   Usuario, 
		   Pass, 
		   EsAdministrador from @TablaUsuarios

	---------------------------PARA PARSEAR USUARIO PUEDE VER---------------------------
	DECLARE @UsuariosPV AS XML
	SELECT @UsuariosPV =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//UsuarioPuedeVer')
	

	--Tabla variable
		 DECLARE @TablaUsuariosPV TABLE(Usuario nchar(30), 
									  numCuenta int)

		DECLARE @UsuarioPV TABLE(ID INT IDENTITY, usuario nchar(30))
		DECLARE @numCuentaPV TABLE(ID INT IDENTITY, numCuenta nchar(30))

		--Insertar en la tabla 
		INSERT INTO @UsuarioPV (usuario)
		SELECT 	xmlData.A.value('.', 'nchar(60)') AS Usuario 
		FROM	@UsuariosPV.nodes('/UsuarioPuedeVer/@User') xmlData(A)

		INSERT INTO @numCuentaPV (numCuenta)
		SELECT 	xmlData.A.value('.', 'int') AS numCuenta 
		FROM	@UsuariosPV.nodes('/UsuarioPuedeVer/@NumeroCuenta') xmlData(A)

		INSERT INTO @TablaUsuariosPV(Usuario, numCuenta)
		SELECT U.usuario, N.numCuenta 
		FROM @UsuarioPV AS U
		LEFT JOIN @numCuentaPV AS N ON N.ID = U.ID

		INSERT INTO dbo.UsuarioPuedeVer(usernameID, numCuentaID)
		SELECT Usuario, numCuenta FROM @TablaUsuariosPV

	

	---------------------------PARA PARSEAR MOVIMIENTOS---------------------------
	DECLARE @Movimientos AS XML
	SELECT @Movimientos =  @XML.query('Operaciones/FechaOperacion[@Fecha=sql:variable("@Fecha")]//Movimientos')
	
	 ------------------------------
	 --Tabla variable
	 DROP TABLE IF EXISTS #TablaMovimientos
	 CREATE TABLE #TablaMovimientos(ID INT IDENTITY, 
									Tipo int, 
									CodigoCuenta int, 
									Monto float, 
									Descripcion nchar(30), 
									Fecha date, 
									Visible bit, 
									EstadodeCuenta int)
	 
	 DECLARE @Tipo TABLE(ID INT IDENTITY,Tipo int)
	 DECLARE @CodigoCuenta TABLE(ID INT IDENTITY,codigo int)
	 DECLARE @Monto TABLE(ID INT IDENTITY,monto float)
	 DECLARE @Descripcion TABLE(ID INT IDENTITY,descripcion nchar(30))

	 --Insertar en la tabla 
	 INSERT INTO @Tipo (Tipo)
		SELECT 	xmlData.A.value('.', 'int') AS Tipo 
		FROM	@Movimientos.nodes('/Movimientos/@Tipo') xmlData(A)

	 INSERT INTO @CodigoCuenta (codigo)
		SELECT 	xmlData.A.value('.', 'int') AS CodigoCuenta 
		FROM	@Movimientos.nodes('/Movimientos/@CodigoCuenta') xmlData(A)

	 INSERT INTO @Monto (monto)
		SELECT 	xmlData.A.value('.', 'float') AS Monto 
		FROM	@Movimientos.nodes('/Movimientos/@Monto') xmlData(A)

	 INSERT INTO @Descripcion (descripcion)
		SELECT 	xmlData.A.value('.', 'nchar(30)') AS Descripcion 
		FROM	@Movimientos.nodes('/Movimientos/@Descripcion') xmlData(A)

		
			

	INSERT INTO #TablaMovimientos(Tipo, 
								  CodigoCuenta, 
								  Monto, 
								  Descripcion)

	SELECT T.Tipo, CC.codigo, M.monto, D.descripcion
	from @Tipo as T
	LEFT JOIN @CodigoCuenta as CC on CC.ID = T.ID
	LEFT JOIN @Monto as M on M.ID = T.ID
	LEFT JOIN @Descripcion as D on D.ID = T.ID
	
	-----*EMPIEZA EL PROCESAMIENTO*-----

	--Recorremos la tabla de movimientos creada para asignar un estado de cuenta
	Declare @lo int, @hi int
	SELECT @lo = 1
	SELECT @hi = COUNT(ID) from #TablaMovimientos
	
	WHILE @lo <= @hi
	BEGIN
		--SACAMOS EL NÚMERO DE CUENTA ASOCIADO AL MOVIMIENTO
		DECLARE @CodigoCuentaActual as int
		SELECT @CodigoCuentaActual = CodigoCuenta FROM #TablaMovimientos WHERE ID = @lo
		
		--ver si la fecha del movimiento coincide con un estado de cuenta
		DECLARE @cantEstadosCuenta as int
		SELECT @cantEstadosCuenta = COUNT (ID)
		FROM dbo.EstadodeCuenta
		WHERE @Fecha BETWEEN FechaInicio and FechaFin AND CuentadeAhorroID = @CodigoCuentaActual

		
		DECLARE @EstadodeCuentaID as int --se usará en ambas condiciones

		--si encuentra un estado de cuenta que coincida con la fecha del movimiento
		IF @cantEstadosCuenta > 0
		BEGIN
			--TOMAMOS EL ID DEL ESTADO DE CUENTA ENCONTRADO
			Select @EstadodeCuentaID = ID FROM dbo.EstadodeCuenta 
			WHERE @Fecha BETWEEN FechaInicio AND FechaFin --agregar cuentaID --verificamos que la fecha del movimiento esté dentro del rango del movimiento

			--buscamos el nuevo saldo
			DECLARE @nuevoSaldo as float
			DECLARE @SaldoFinalEC as float
			DECLARE @MontoMovimiento as float
			DECLARE @TipoMovID as int

			SELECT @SaldoFinalEC = SaldoFinal FROM dbo.EstadodeCuenta 
			WHERE ID = @EstadodeCuentaID

			SELECT @MontoMovimiento = Monto FROM #TablaMovimientos WHERE ID = @lo
			SELECT @TipoMovID = Tipo FROM #TablaMovimientos WHERE ID = @lo --uno solo

			--Dependiendo del tipo de movimiento, establecemos el nuevo saldo
			IF @TipoMovID = 1 OR @TipoMovID = 2 OR @TipoMovID = 3
				SET @nuevoSaldo = @SaldoFinalEC - @MontoMovimiento
			ELSE 
				SET @nuevoSaldo = @SaldoFinalEC + @MontoMovimiento

			--CAMBIAMOS LOS SALDOS DEL ESTADO DE CUENTA CON UN UPDATE
			UPDATE dbo.EstadodeCuenta
			SET SaldoInicial = SaldoFinal
			WHERE ID = @EstadodeCuentaID

			UPDATE dbo.EstadodeCuenta
			SET SaldoFinal = @nuevoSaldo
			WHERE ID = @EstadodeCuentaID --cambiar, aqui no

			--Actualiza el saldo de la cuenta de ahorro
			DECLARE @SaldoCA as float
			DECLARE @numCuentaID as int
			SELECT @numCuentaID = CodigoCuenta FROM #TablaMovimientos WHERE ID = @lo
			SELECT @SaldoCA = Saldo FROM dbo.CuentadeAhorro WHERE NumerodeCuenta = @numCuentaID

			--Definimos tipo de movimiento
			IF @TipoMovID = 1 OR @TipoMovID = 2 OR @TipoMovID = 3
				UPDATE dbo.CuentadeAhorro
				SET Saldo = Saldo - @MontoMovimiento
				WHERE NumerodeCuenta = @numCuentaID
			ELSE
				UPDATE dbo.CuentadeAhorro
				SET Saldo = Saldo + @MontoMovimiento
				WHERE NumerodeCuenta = @numCuentaID

			--INGRESAMOS EL MOVIMIENTO A LOS REGISTROS
			DECLARE @TipoFinal as int
			DECLARE @MontoFinal as float
			DECLARE @DescripcionFinal as nchar(30)

			SELECT @TipoFinal = Tipo FROM #TablaMovimientos WHERE ID = @lo
			SELECT @MontoFinal = Monto FROM #TablaMovimientos WHERE ID = @lo
			SELECT @DescripcionFinal = Descripcion FROM #TablaMovimientos WHERE ID = @lo
			

			INSERT INTO dbo.MovimientoCA(EstadodeCuentaID, TipoMovCAID,numCuentaID, Fecha, Monto, NuevoSaldo, Descripcion, Visible)
			SELECT @EstadodeCuentaID, @TipoFinal,@numCuentaID, @Fecha, @MontoFinal, @nuevoSaldo, @DescripcionFinal, 1
			SET @lo = @lo+1
		END

		--Aquí es cuando no hace match con ningún estado de cuenta
		ELSE
		BEGIN
			--BUSCAMOS EL ID DEL ÚLTIMO ESTADO DE CUENTA
			DECLARE @totalEstadosdeCuenta as int
			SELECT @totalEstadosdeCuenta = COUNT(*) FROM dbo.EstadodeCuenta --maxID

			DECLARE @ultimoEstadodeCuentaID as int
			SELECT @ultimoEstadodeCuentaID = ID FROM dbo.EstadodeCuenta WHERE ID =@totalEstadosdeCuenta

			--Buscamos el número de cuenta asociado
			DECLARE @NumCuentaEstado as int
			SELECT @NumCuentaEstado = CuentadeAhorroID FROM DBO.EstadodeCuenta WHERE ID = @ultimoEstadodeCuentaID

			--Buscamos el tipo de Cuenta de Ahorro
			DECLARE @TipoCA as int
			SELECT @TipoCA = TipoCuentaAhorroID FROM dbo.CuentadeAhorro WHERE ID = @NumCuentaEstado

			-------*Aplicamos los cargos por comisión*-------

			--Primero el cargo anual
			DECLARE @CargoAnual as float
			SELECT @CargoAnual = CargoAnual from dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			UPDATE dbo.CuentadeAhorro
			SET Saldo = Saldo - @CargoAnual
			WHERE NumerodeCuenta = @NumCuentaEstado

			--La multa por saldo mínimo
			DECLARE @multaSaldoMinimo as float, @saldominimo as float
			SELECT @multaSaldoMinimo = MultaSaldoMinimo FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA
			SELECT @saldominimo = SaldoMinimo FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA
			
			IF @SaldoCA < @saldominimo
				UPDATE dbo.CuentadeAhorro
				SET Saldo = Saldo - @multaSaldoMinimo
				WHERE NumerodeCuenta = @NumCuentaEstado

			
			--Max Operaciones Cajero Humano

			--Se saca la cantidad de movimientos por cajero humano realizados
			DECLARE @cantMovCajeroHumano as int
			SELECT @cantMovCajeroHumano = COUNT (*) FROM dbo.MovimientoCA 
			WHERE TipoMovCAID = 3 or TipoMovCAID = 5 and EstadodeCuentaID = @ultimoEstadodeCuentaID

			--Se saca el máximo de operaciones por cajero humano permitidas
			DECLARE @maxOPCajeroHumano as int
			SELECT @maxOPCajeroHumano = MaxOPCajeroHumano FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			--Se saca el monto de la comisión
			DECLARE @comisionMaxOPCajeroHumano as float
			SELECT @comisionMaxOPCajeroHumano = ComisionOPCajeroHumano 
			FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			--Se hace el rebajo en el saldo de la cuenta
			IF @cantMovCajeroHumano > @maxOPCajeroHumano
				UPDATE dbo.CuentadeAhorro
				SET Saldo = Saldo - @comisionMaxOPCajeroHumano
				WHERE NumerodeCuenta = @NumCuentaEstado

			--Max Operaciones Cajero Automatico

			--Se saca la cantidad de movimientos por cajero automatico realizados
			DECLARE @cantMovCajeroAutomatico as int
			SELECT @cantMovCajeroAutomatico = COUNT (*) FROM dbo.MovimientoCA 
			WHERE TipoMovCAID = 2 or TipoMovCAID = 4 and EstadodeCuentaID = @ultimoEstadodeCuentaID

			--Se saca el máximo de operaciones por cajero automatico  permitidas
			DECLARE @maxOPCajeroAutomatico as int
			SELECT @maxOPCajeroAutomatico = MaxOPCajeroAutomatico FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			--Se saca el monto de la comisión
			DECLARE @comisionMaxOPCajeroAutomatico as float
			SELECT @comisionMaxOPCajeroAutomatico = ComisionOPCajeroAutomatico
			FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			--Se hace el rebajo en el saldo de la cuenta
			IF @cantMovCajeroAutomatico > @maxOPCajeroAutomatico
				UPDATE dbo.CuentadeAhorro
				SET Saldo = Saldo - @comisionMaxOPCajeroAutomatico
				WHERE NumerodeCuenta = @NumCuentaEstado

			--Tasa de interés
			DECLARE @TasaInteres as float
			SELECT @TasaInteres = TasaInteres FROM dbo.TipoCuentaAhorro WHERE ID = @TipoCA

			UPDATE dbo.CuentadeAhorro
			SET Saldo = Saldo + (Saldo*@TasaInteres)/100 --minimo/estado de cuenta / dividido entre 12*
			WHERE NumerodeCuenta = @NumCuentaEstado

			--Se crea el nuevo estado de cuenta***

			--se definen fecha de inicio y de fin
			DECLARE @FechaFinEstadoAnterior as date, @FechaInicio as date, @FechaFin as date
			
			SELECT @FechaFinEstadoAnterior = FechaFin FROM dbo.EstadodeCuenta WHERE ID = @ultimoEstadodeCuentaID
			SET @FechaInicio = DATEADD(DAY, 1, @FechaFinEstadoAnterior)
			SET @FechaFin = DATEADD(MONTH, 1, @FechaInicio)
			SET @FechaFin = DATEADD(DAY, -1, @FechaFin)

			--Se definen saldo inicial y final
			DECLARE @SaldoFinalEstadoAnterior as float, @saldoInicial as float, @saldoFinal as float
			SELECT @SaldoFinalEstadoAnterior = SaldoFinal FROM dbo.EstadodeCuenta WHERE ID = @ultimoEstadodeCuentaID

			SET @saldoInicial = @SaldoFinalEstadoAnterior
			SET @saldoFinal = @SaldoFinalEstadoAnterior

			INSERT INTO dbo.EstadodeCuenta(CuentadeAhorroID, FechaInicio, FechaFin, SaldoInicial, SaldoFinal)
			VALUES (@NumCuentaEstado, @FechaInicio, @FechaFin, @saldoInicial, @saldoFinal)

		END
	
	END