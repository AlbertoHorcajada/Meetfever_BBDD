USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrado_Real_MeGusta_Por_ID]    Script Date: 15/06/2022 11:07:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Procedimiento almacenado encargado de hacer un borrado real de un "MeGusta" de un Usuario a una Opinion
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrado_Real_MeGusta_Por_ID]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'MeGusta eliminado'
		DECLARE @IDOPINION INT
		DECLARE @IDUSUARIO INT
		DECLARE @JSONOPINION NVARCHAR(MAX)
		DECLARE @JSONUSUARIO NVARCHAR(MAX)
		DECLARE @JSONPRUEBA NVARCHAR(MAX)
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @IDOPINION = Id_Opinion
				FROM
					OPENJSON (@JSON_IN) WITH (Id_Opinion INT '$.Id_Opinion')

			SELECT @IDUSUARIO = Id_Usuario
				FROM
					OPENJSON (@JSON_IN) WITH (Id_Usuario INT '$.Id_Usuario')
			-- Comrpobaciones de ese ID
		
			IF (@IDOPINION IS NULL OR @IDUSUARIO IS NULL)
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE = 'No llega el ID de alguno de los usuarios'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@IDOPINION = '' OR @IDUSUARIO = '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'Alguno de los ID de usuarios vacios'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@IDOPINION <0 OR @IDUSUARIO <0)
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'Alguno o ambos ID son menores que 0'
					SET @JSON_OUT = '{"Exito":false}'
				END

			SET NOCOUNT ON;

			-- Comprobar que de verdad existe el MeGusta y si es así eliminarlo

			SET @JSONOPINION = (
			SELECT *
			FROM Opinion
			WHERE Id = @IDOPINION
			FOR JSON PATH)

			SET @JSONUSUARIO = (
			SELECT *
			FROM Usuario
			WHERE Id = @IDUSUARIO
			FOR JSON PATH)

			IF (@JSONOPINION IS NULL OR @JSONUSUARIO IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Usuario u Opinion inexistente'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN

					SET @JSONPRUEBA = (
						SELECT *
							FROM MeGusta
							WHERE Id_Opinion = @IDOPINION AND Id_Usuario = @IDUSUARIO
					FOR JSON PATH)
					
					IF(@JSONPRUEBA IS NULL)
						BEGIN
							SET @RETCODE = 5
							SET @MENSAJE  = 'No existe el like'
							SET @JSON_OUT = '{"Exito":false}'
						END
						ELSE
							BEGIN
								DELETE FROM MeGusta 
									WHERE Id_Usuario = @IDUSUARIO AND Id_Opinion = @IDOPINION
								SET @JSON_OUT = '{"Exito":true}'
							END
						
				END



		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH

