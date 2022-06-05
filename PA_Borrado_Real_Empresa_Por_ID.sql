USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrado_Real_Empresa_Por_ID]    Script Date: 05/06/2022 18:00:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption:	Procedimiento almacenado que se ecarga de hacer un borrado real de una empresa recibiendo un ID
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrado_Real_Empresa_Por_ID]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa eliminada realmente exitosamente'
		DECLARE @ID INT
		DECLARE @JSONPRUEBA NVARCHAR(MAX)
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
					SET @MENSAJE = 'ID nulo'
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
					SET @MENSAJE = 'ID no valido, numero negativo'
					SET @JSON_OUT = '{"Exito":false}'
				END

			SET NOCOUNT ON;

			-- Comprobar que de verdad existe el usuario y si es asi pasar todo a borrado logico

			SET @JSONPRUEBA = (
			SELECT *
			FROM Empresa
			WHERE Id = @ID
			FOR JSON PATH)

			IF (@JSONPRUEBA IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'No existe el id'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN

					
					DELETE FROM Seguidor_Seguido WHERE Seguido = @ID

					DELETE FROM Seguidor_Seguido WHERE Seguidor = @ID
				
					DELETE FROM MeGusta WHERE Id_Usuario = @ID

					DELETE FROM MeGusta WHERE Id = ANY (
						SELECT Id
						FROM Opinion
						WHERE Id_Autor = @ID
					)

					DELETE FROM Opinion WHERE Id_Autor = @ID

					DELETE FROM Experiencia WHERE Id_Empresa = @ID

					DELETE FROM Empleado WHERE Id_Empresa = @ID

					DELETE FROM Empresa WHERE id = @ID

					DELETE FROM Usuario WHERE Id = @ID				
				
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
