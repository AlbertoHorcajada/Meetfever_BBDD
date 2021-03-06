USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_MeGusta]    Script Date: 15/06/2022 11:11:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta o eliminar un MG
-- ============================================

	ALTER PROCEDURE [dbo].[PA_MeGusta]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'MG insertado'


		DECLARE @ID_OPINION INT
		DECLARE @ID_USUARIO INT
		DECLARE @ID INT
		


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		
		-- Recuperacion de los datos del JSON entrante

	BEGIN TRY

		BEGIN TRANSACTION

				SELECT @ID_OPINION = Id_Opinion,
					@ID_USUARIO = Id_Usuario
					FROM
						OPENJSON (@JSON_IN) 
						WITH (Id_Opinion INT '$.Id_Opinion',
						Id_Usuario INT '$.Id_Usuario')



				-- Comprobaciones de que los campos obligatorios tienen informacion

				if(@ID_OPINION IS NULL)
					BEGIN
						SET @RETCODE = 1
						SET @MENSAJE =  'Opinion Vacia'
					END
				ELSE IF (@ID_USUARIO IS NULL)
					BEGIN
						SET @RETCODE = 2
						SET @MENSAJE = 'Usuario vacio'
					END


				-- Comrpobaciones de que las claves foraneas existen

				SET @JSON_PRUEBA = (
					SELECT U.Id
					FROM Usuario U
					WHERE U.Id = @ID_USUARIO AND U.Eliminado = 0
				FOR JSON AUTO)

				IF(@JSON_PRUEBA IS NULL)
					BEGIN 
						SET @RETCODE = 3
						SET @MENSAJE = 'No existe el usuario'
					END
				ELSE
					BEGIN 
						SET @JSON_PRUEBA = NULL
						SET @JSON_PRUEBA = (
							SELECT o.Id
							FROM Opinion o
							WHERE o.Id = @ID_OPINION AND o.Eliminado = 0
						FOR JSON AUTO)

						IF (@JSON_PRUEBA IS NULL)
							BEGIN
								SET @RETCODE = 4
								SET @MENSAJE = 'No existe la opinion'
							END
					END
				SET NOCOUNT ON;
				IF(@RETCODE = 0)
					BEGIN
						-- Primero tengo que comprobar si existe ya el caso en el que se le dio MG desde un usuario a una opinion
						SET @JSON_PRUEBA = NULL
						SET @JSON_PRUEBA = (
							SELECT Mg.*
							FROM MeGusta Mg
							WHERE Id_Opinion = @ID_OPINION AND Id_Usuario = @ID_USUARIO
							FOR JSON AUTO
						)

						-- Hacemos la prueba de si hay algo es que existe

						IF (@JSON_PRUEBA IS NULL)
							BEGIN
								INSERT INTO MeGusta(Id_Opinion, Id_Usuario) VALUES (@ID_OPINION, @ID_USUARIO)
								SET @MENSAJE = 'Me Gusta'
								SET @JSON_OUT = '{"MeGusta":"True"}'
							END
						ELSE
							BEGIN
								DELETE MeGusta WHERE Id_Opinion = @ID_OPINION AND Id_Usuario = @ID_USUARIO
								SET @MENSAJE = 'No Me Gusta'
								SET @JSON_OUT = '{"MeGusta":"False"}'
							END

				END
		
		
		COMMIT TRANSACTION
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		ROLLBACK TRANSACTION
	END CATCH
		