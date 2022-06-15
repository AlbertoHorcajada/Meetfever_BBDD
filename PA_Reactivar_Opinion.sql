USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Reactivar_Opinion]    Script Date: 15/06/2022 11:21:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Procedimiento Almacenado que elimina el borrado logico de una opinión
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Reactivar_Opinion]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Opinion reactivada'
		DECLARE @ID INT
		DECLARE @JSONOPINION NVARCHAR(MAX)
		-- Recuperacion del ID del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id
				FROM
					OPENJSON (@JSON_IN) WITH (Id INT '$.Id')

			-- Comrpobaciones de ese ID
		
			IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE = 'No llega el ID'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@ID = '')
				BEGIN
					SET @RETCODE = 2
					SET @MENSAJE = 'ID vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END

			IF (@ID <0)
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'ID menor que 0'
					SET @JSON_OUT = '{"Exito":false}'
				END

			SET NOCOUNT ON;

			-- Comprobar que de verdad existe el usuario y si es asi pasar todo a borrado logico

			SET @JSONOPINION = (
			SELECT *
			FROM Opinion
			WHERE Id = @ID
			FOR JSON PATH)

			IF (@JSONOPINION IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'No existe la opinion'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN

					UPDATE Opinion SET Eliminado = 0 WHERE Id = @ID
				

					SET @JSON_OUT = '{"Exito":true}'
				END


		COMMIT TRANSACTION
		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH

