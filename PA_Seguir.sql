USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Seguir]    Script Date: 15/06/2022 11:22:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta o eliminar un Seguidor
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Seguir]
	
		@JSON_IN NVARCHAR(MAX), 
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT,
		@JSON_OUT NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Seguidor insertado'


		DECLARE @ID_SEGUIDOR INT
		DECLARE @ID_SEGUIDO INT
		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		
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
				SET @JSON_OUT = '{"Exito":false}'

			END
		ELSE IF (@ID_SEGUIDO IS NULL)
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Seguido vacio'
				SET @JSON_OUT = '{"Exito":false}'

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
				SET @JSON_OUT = '{"Exito":false}'

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
						SET @JSON_OUT = '{"Exito":false}'

					END
			END

			-- Comprobar que existe la empresa
		IF(@RETCODE = 0)
		BEGIN
			-- Primero tengo que comprobar si existe ya el caso en el que se le dio MG desde un usuario a una opinion
			SET @JSON_PRUEBA = NULL
			SET @JSON_PRUEBA = (
				SELECT s.Id
				FROM Seguidor_Seguido s
				WHERE s.Seguido = @ID_SEGUIDO AND s.Seguidor = @ID_SEGUIDOR
				FOR JSON AUTO
			)

			-- Hacemos la prueba de si hay algo es que existe

			IF (@JSON_PRUEBA IS NULL)
				BEGIN
					INSERT INTO Seguidor_Seguido(Seguidor, Seguido) VALUES (@ID_SEGUIDOR, @ID_SEGUIDO)
					SET @MENSAJE = 'Seguido'
					SET @JSON_OUT = '{"Seguido":true}'
				END
			ELSE
				BEGIN
					DELETE FROM Seguidor_Seguido WHERE Seguido = @ID_SEGUIDO AND Seguidor = @ID_SEGUIDOR
					SET @MENSAJE = 'dejado de seguir'
					SET @JSON_OUT = '{"Seguido":false}'
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
		