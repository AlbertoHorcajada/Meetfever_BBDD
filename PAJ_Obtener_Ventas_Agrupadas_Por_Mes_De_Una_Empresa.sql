USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PAJ_Obtener_Ventas_Agrupadas_Por_Mes_De_Una_Empresa]    Script Date: 15/06/2022 11:23:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Julio Landazuri
-- Create date: 24/04/2022
-- Descrption: Devuelve las ventsa de una empresa agrupadas por Mes
-- ============================================

	ALTER PROCEDURE [dbo].[PAJ_Obtener_Ventas_Agrupadas_Por_Mes_De_Una_Empresa]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Ventas encontradas exitosamente'
		DECLARE @ID_EMPRESA INT

		DECLARE @JSONPRUEBA NVARCHAR(MAX)
		DECLARE @FIRST_DAY_OF_YEAR DATETIME

		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		SELECT @ID_EMPRESA = Id_Empresa
			FROM
				OPENJSON (@JSON_IN) WITH (Id_Empresa INT '$.Id_Empresa')
		-- Comrpobaciones de ese ID
		
		IF (@ID_EMPRESA IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'ID nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EMPRESA = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'ID vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@ID_EMPRESA <0)
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'ID menor que 0'
				SET @JSON_OUT = '{"Exito":false}'
			END

		IF (@RETCODE = 0)
			BEGIN
				SET @JSONPRUEBA = (
					SELECT Id
					From Empresa
					WHERE Id = @ID_EMPRESA AND Eliminado = 0
				)

				IF (@JSONPRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'Empresa inexistente o borrada de forma logica'
						SET @JSON_OUT = '{"Exito":false}'
					END

			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta
	IF (@RETCODE = 0)
	BEGIN

			SET @FIRST_DAY_OF_YEAR = (SELECT DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0))

			DECLARE @MesesFounds TABLE(
				Mes Int,
				Ventas Int
			)

			INSERT INTO @MesesFounds
			SELECT 

					MONTH(ep.Fecha),
					COUNT(ep.Id)

			FROM
				Entrada_Persona ep INNER JOIN Experiencia e ON (ep.Id_Experiencia = e.Id)
				INNER JOIN Empresa em ON (e.Id_Empresa = em.Id)

				WHERE em.Id = @ID_EMPRESA AND ep.Fecha >= @FIRST_DAY_OF_YEAR

				GROUP BY MONTH(ep.Fecha)
				
		
		DECLARE @Meses TABLE(
			Mes Int,
			Ventas Int
		)

		DECLARE @Mes Int = 1

		DECLARE @MesValue Int
		DECLARE @VentaValue Int

		WHILE @Mes <= 12
			BEGIN
		
				SET @MesValue = (SELECT Mes FROM @MesesFounds WHERE Mes = @Mes)

					IF(@MesValue IS NULL OR @MesValue = '')
					BEGIN
						INSERT INTO @Meses VALUES(@Mes,0)
					END
				ELSE
					BEGIN
						INSERT INTO @Meses
						SELECT Mes, Ventas
						FROM @MesesFounds
						WHERE Mes = @Mes
					END

			   
				SET @Mes = @Mes+1
			END

		SET @JSON_OUT = ( SELECT * FROM @Meses FOR JSON PATH )

		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 5
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 6
				SET @MENSAJE = 'Ventas no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
