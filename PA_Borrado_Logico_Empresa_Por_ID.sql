USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Borrado_Logico_Empresa_Por_ID]    Script Date: 15/06/2022 11:06:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption:	Procedimiento almacenado que se ecarga de hacer un borrado logico de una empresa recibiendo un ID
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Borrado_Logico_Empresa_Por_ID]
	
		@JSON_IN NVARCHAR(MAX),
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Empresa eliminada'
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
					SET @MENSAJE = 'ID menor que 0'
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
					SET @MENSAJE = 'No existe la empresa'
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE
				BEGIN

					-- ELIMINO LOS SEGUIDORES  Y SEGUIDOS HACIA SU CUENTA
					DELETE Seguidor_Seguido WHERE Seguidor = @ID
				
					DELETE Seguidor_Seguido WHERE Seguido = @ID

					--ELIMINO LOS MEGUSTAS QUE HA DADO

					DELETE MeGusta WHERE Id_Usuario = @ID

					-- ELIMINO LOS MEGUSTAS REFERENTES A LAS OPINIONES DE UN USUARIO

					DELETE MeGusta WHERE Id_Opinion = ANY (
								SELECT id
								from Opinion
								where Id_Autor = @ID
					)

					-- ELIMINO LAS OPINIONES DEL USUARIO
				
					UPDATE Opinion SET Eliminado = 1 WHERE Id_Autor = @ID

					-- ELIMINO LAS EXPERIENCIAS

					UPDATE Experiencia SET Eliminado = 1 WHERE Id_Empresa = @ID

					-- ELIMINO LOS EMPLEADOS

					UPDATE Empleado SET Eliminado = 1 WHERE Id_Empresa = @ID

					-- ELIMINO EL USUARIO FINAL

					UPDATE Empresa SET Eliminado = 1 WHERE Id = @ID

					UPDATE Usuario SET Eliminado = 1 WHERE Id = @ID
				
					SET @JSON_OUT = '{"Exito":true}'

				COMMIT TRANSACTION
			END

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
