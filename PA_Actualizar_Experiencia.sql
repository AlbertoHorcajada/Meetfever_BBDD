USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Actualizar_Experiencia]    Script Date: 15/06/2022 11:05:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Actualiza una Experiencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Actualizar_Experiencia]
	
		@JSON_IN NVARCHAR(MAX), 
		@INVOKER INT,
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencia Actualizada exitosamente'

		DECLARE @ID INT
		DECLARE @TITULO VARCHAR(50)
		DECLARE @DESCRIPCION VARCHAR(255)
		DECLARE @FECHA_CELEBRACION DATETIME
		DECLARE @PRECIO DECIMAL(6,2)
		DECLARE @AFORO INT
		DECLARE @FOTO NVARCHAR(MAX)
		DECLARE @ID_EMPRESA INT


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
	
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT @ID = Id, 
				@TITULO = Titulo, 
				@DESCRIPCION = Descripcion, 
				@FECHA_CELEBRACION = Fecha_Celebracion, 
				@PRECIO = Precio, 
				@AFORO = Aforo,
				@FOTO = Foto,
				@ID_EMPRESA = Id_Empresa
				FROM
					OPENJSON (@JSON_IN) 
					WITH (Id INT '$.Id',
					Titulo VARCHAR(50) '$.Titulo',
					Descripcion VARCHAR(255) '$.Descripcion',
					Fecha_Celebracion DATETIME '$.Fecha_Celebracion',
					Precio DECIMAL(6,2) '$.Precio',
					Aforo INT '$.Aforo',
					Foto NVARCHAR(MAX) '$.Foto',
					Id_Empresa INT '$.Empresa.Id')

			if(@TITULO IS NULL or @TITULO = '')
				BEGIN
					SET @RETCODE = 1
					SET @MENSAJE =  'Titulo vacio'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF (@DESCRIPCION IS NULL OR @DESCRIPCION = '')
				BEGIN
					SET @RETCODE = 2
					SET @RETCODE = 'Descripcion vacia'
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@FECHA_CELEBRACION IS NULL)
				BEGIN
					SET @RETCODE = 3
					SET @MENSAJE = 'Fecha de celebracion vacia' 
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@PRECIO IS NULL)
				BEGIN
					SET @RETCODE = 4
					SET @MENSAJE = 'Precio vacio' 
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@AFORO IS NULL )
				BEGIN
					SET @RETCODE = 5
					SET @MENSAJE = 'Aforo vacio' 
					SET @JSON_OUT = '{"Exito":false}'
				END

			ELSE IF(@ID_EMPRESA IS NULL OR @ID_EMPRESA = '')
				BEGIN
					SET @RETCODE = 6
					SET @MENSAJE = 'Id_Empresa vacío' 
					SET @JSON_OUT = '{"Exito":false}'
				END
			ELSE IF (@ID IS NULL)
				BEGIN
					SET @RETCODE = 7
					SET @MENSAJE = 'Id_Experiencia vacío'
					SET @JSON_OUT = '{"Exito":false}'
				END
			
			IF(@RETCODE = 0)
				BEGIN
					SET @JSON_PRUEBA = (
					SELECT 
					e.Id
					FROM Empresa e
					where e.Id = @ID_EMPRESA and e.Eliminado = 0
					FOR JSON PATH)

					If (@JSON_PRUEBA is null or @JSON_PRUEBA = '')
						BEGIN
							SET @RETCODE = 8
							SET @MENSAJE = 'Empresa inexistente o eliminada de forma logica'
							SET @JSON_OUT = '{"Exito":false}'
						END
			
		
				END


				IF (@RETCODE = 0)
				BEGIN
					SET @JSON_PRUEBA = NULL

					SET @JSON_PRUEBA = (
						SELECT e.Id
							FROM Experiencia e
								WHERE e.Id = @ID AND e.Eliminado = 0
					FOR JSON AUTO)

					IF (@JSON_PRUEBA IS NULL)
						BEGIN
							SET @RETCODE = 9
							SET @MENSAJE = 'Experiencia inexistente o borrada de forma logica'
							SET @JSON_OUT = '{"Exito":false}'
						END

				END


			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN

					UPDATE Experiencia
						SET
							Titulo =@TITULO ,
							Descripcion = @DESCRIPCION,
							Fecha_Celebracion = @FECHA_CELEBRACION,
							Precio = @PRECIO,
							Aforo = @AFORO,
							Foto= @FOTO,
							Id_Empresa = @ID_EMPRESA
						WHERE Id = @ID
					SET @JSON_OUT = '{"Exito":true}'
				END
			ELSE
				BEGIN
					SET @JSON_OUT = '{"Exito":false}'
				END
		
		COMMIT TRANSACTION	

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		