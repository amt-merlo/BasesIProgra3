--Se hace una tabla para guardar los datos solicitados de la consulta
DECLARE @ConsultaCuentas TABLE(ID INT IDENTITY, 
							   CodigoCA INT, 
							   CuentaObjetivoID INT, 
							   Descripcion nchar(60), 
							   CantDepositosValidos int, 
							   CantDepositosTotales int, 
							   MontoDebitadoReal int, 
							   MontoDebitadoTotal int)

--Se hace una tabla que guarda todos los ID de las cuentas que tuvieron inconvenientes
DECLARE @Cuentas TABLE(ID INT IDENTITY, CuentaID int)
--Se insertan los ID´s
INSERT INTO @Cuentas(CuentaID)
SELECT DISTINCT CuentaObjetivoID FROM MovCO WHERE Valido = 0 --Distinct para que no se repitan

--Variables para el while que recorre las cuentas
DECLARE @lo as int, @hi as int
SET @lo = 1
SELECT @hi = COUNT (*) FROM @Cuentas


--RECORREMOS LAS CUENTAS
WHILE @lo <= @hi
BEGIN
	DECLARE @CuentaObjID as int
	SELECT @CuentaObjID = CuentaID FROM @Cuentas WHERE ID = @lo

	DECLARE @CodigoCA as int, 
			@descripcion as nchar(60), 
			@cantDepositosValidos as int, 
			@cantDepositosTotales as int, 
			@montoDebitadoReal as float, 
			@montoDebitadoTotal as float

	SELECT @CodigoCA = CuentadeAhorroID FROM CuentaObjetivo WHERE ID = @CuentaObjID
	SELECT @descripcion = Objetivo FROM CuentaObjetivo WHERE ID = @CuentaObjID

	--CONTAMOS LOS DEPÓSITOS VÁLIDOS
	SELECT @cantDepositosValidos = COUNT (*) FROM MovCO WHERE (TipoMovCOID = 1 AND CuentaObjetivoID = @CuentaObjID AND Valido = 1)
	SELECT @cantDepositosTotales = COUNT (*) FROM MovCO WHERE (TipoMovCOID = 1 AND CuentaObjetivoID = @CuentaObjID)
	
	--Calculamos el monto debitado real
	
	DECLARE @MovimientosValidos TABLE(ID INT IDENTITY, MovID INT)

	INSERT INTO @MovimientosValidos (MovID)
	SELECT ID FROM MovCO WHERE CuentaObjetivoID = @CuentaObjID AND TipoMovCOID = 1 AND Valido = 1

	--Variables para recorrer los movimientos y acumular el monto
	DECLARE @contador as int, @tope as int, @monto as float
	SET @contador = 1
	SELECT @tope = COUNT (*) FROM @MovimientosValidos
	SET @monto = 0

	WHILE @contador <= @tope
	BEGIN
		DECLARE @MovimientoID as int
		SELECT @MovimientoID = MovID FROM @MovimientosValidos WHERE ID = @contador

		DECLARE @CantidadMonetaria as float
		SELECT @CantidadMonetaria = Monto FROM MovCO WHERE ID = @MovimientoID

		--SUMAMOS EL MONTO
		SET @monto = @monto + @CantidadMonetaria

		SET @contador = @contador + 1
	END

	--Calculamos el monto debitado ficticio sin los incovenientes de falta de fondos
	DECLARE @MovimientosTotales TABLE(ID INT IDENTITY, MovID INT)

	INSERT INTO @MovimientosTotales (MovID)
	SELECT ID FROM MovCO WHERE CuentaObjetivoID = @CuentaObjID AND TipoMovCOID = 1 

	--Variables para recorrer los movimientos y acumular el monto
	DECLARE @menor as int, @mayor as int, @montoTotal as float
	SET @menor = 1
	SELECT @mayor = COUNT (*) FROM @MovimientosTotales
	SET @montoTotal = 0

	WHILE @menor <= @mayor
	BEGIN
		DECLARE @MovimientoID2 as int
		SELECT @MovimientoID2 = MovID FROM @MovimientosTotales WHERE ID = @menor

		DECLARE @CantidadMonetaria2 as float
		SELECT @CantidadMonetaria2 = Monto FROM MovCO WHERE ID = @MovimientoID2

		--SUMAMOS EL MONTO
		SET @montoTotal = @montoTotal + @CantidadMonetaria2

		SET @menor = @menor + 1
	END

	SELECT @monto
	select @montoTotal
	SET @lo = @lo + 1

	--DEFINIMOS LOS VALORES DE LOS MONTOS
	SET @montoDebitadoReal = @monto
	SET @montoDebitadoTotal = @montoTotal

	--INSERTAMOS LA INFORMACIÓN EN LA TABLA
	INSERT INTO @ConsultaCuentas (CodigoCA,
								  CuentaObjetivoID,
							      Descripcion,
							      CantDepositosValidos,
							      CantDepositosTotales,
							      MontoDebitadoReal,
							      MontoDebitadoTotal)
	VALUES (@CodigoCA, 
			@CuentaObjID, 
			@descripcion, 
			@cantDepositosValidos,
			@cantDepositosTotales,
			@montoDebitadoReal, 
			@montoDebitadoTotal)
END



INSERT INTO ConsultaAdmin1(CodigoCA, CuentaObjetivoID, Descripcion, CantDepositosValidos, CantDepositosTotales, MontoDebitadoReal, MontoDebitadoTotal)
SELECT CodigoCA, CuentaObjetivoID, Descripcion, CantDepositosValidos, CantDepositosTotales, MontoDebitadoReal, MontoDebitadoTotal FROM @ConsultaCuentas

SELECT * FROM @ConsultaCuentas