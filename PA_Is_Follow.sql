USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Is_Follow]    Script Date: 15/06/2022 11:11:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que comprueba si sigue a un usuario o no
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Is_Follow]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Encontrado bien'


		DECLARE @ID_SEGUIDOR INT
		DECLARE @ID_SEGUIDO INT
		DECLARE @ID INT
		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		DECLARE @ELIMINADO BIT
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		SELECT @ID_SEGUIDOR = Id_Seguidor,
			@ID_SEGUIDO = Id_Seguido
			FROM
				OPENJSON (@JSON_IN) 
				WITH (Id_Seguidor INT '$.Seguidor',
				Id_Seguido INT '$.Seguido')



		-- Comprobaciones de que los campos obligatorios tienen informacion

		if(@ID_SEGUIDOR IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE =  'Seguidor Vacio'
			END
		ELSE IF (@ID_SEGUIDO IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Seguido vacio'
			END


		-- Comrpobaciones de que las claves foraneas existen

		SET @JSON_PRUEBA = (
			SELECT U.Id
			FROM Usuario U
			WHERE U.Id = @ID_SEGUIDOR AND U.Eliminado = 0
		FOR JSON AUTO)

		IF(@JSON_PRUEBA IS NULL)
			BEGIN 
				SET @RETCODE = 3
				SET @MENSAJE = 'No existe el Seguidor'
			END
		ELSE
			BEGIN 
				SET @JSON_PRUEBA = NULL
				SET @JSON_PRUEBA = (
					SELECT U.Id
					FROM Usuario U
					WHERE U.Id = @ID_SEGUIDO AND U.Eliminado = 0
				FOR JSON AUTO)

				IF (@JSON_PRUEBA IS NULL)
					BEGIN
						SET @RETCODE = 4
						SET @MENSAJE = 'No existe el Seguido'
					END
			END

		IF(@RETCODE = 0)
		BEGIN
			SET @JSON_PRUEBA = NULL
			SET @JSON_PRUEBA = (
				SELECT s.Id
				FROM Seguidor_Seguido s
				WHERE s.Seguido = @ID_SEGUIDO AND s.Seguidor = @ID_SEGUIDOR
				FOR JSON AUTO
			)


			IF (@JSON_PRUEBA IS NOT NULL)
				BEGIN
					SET @RETCODE = 0 -- es 0 porque no es una respuesta erronea
					SET @MENSAJE = 'Si es seguidor'
					SET @JSON_OUT = '{"Mesigue":true}'
				END
			ELSE
				BEGIN
					SET @RETCODE = 0 -- es 0 porque no es una respuesta erronea
					SET @MENSAJE = 'No es seguidor'
					SET @JSON_OUT = '{"Mesigue":false}'
				END

		END
		
		
		

		SET NOCOUNT ON;

		-- Buscar en la BBDD el Usuario por ID y crear el JSON
		
		

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
		