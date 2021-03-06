USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Insertar_Experiencia]    Script Date: 15/06/2022 11:09:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado Inserta una Experiencia
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Insertar_Experiencia]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencia insertada'


		DECLARE @TITULO VARCHAR(50)
		DECLARE @DESCRIPCION VARCHAR(255)
		DECLARE @FECHA_CELEBRACION DATETIME
		DECLARE @PRECIO DECIMAL(6,2)
		DECLARE @AFORO INT
		DECLARE @FOTO NVARCHAR(MAX)
		DECLARE @ID_EMPRESA INT


		DECLARE @JSON_PRUEBA NVARCHAR(MAX)
		-- Recuperacion de los datos del JSON entrante
	BEGIN TRY

		BEGIN TRANSACTION

			SELECT 
				@TITULO = Titulo, 
				@DESCRIPCION = Descripcion, 
				@FECHA_CELEBRACION = Fecha_Celebracion, 
				@PRECIO = Precio, 
				@AFORO = Aforo,
				@FOTO = Foto,
				@ID_EMPRESA = Id_Empresa
				FROM
					OPENJSON (@JSON_IN) 
					WITH (
					Titulo VARCHAR(50) '$.Titulo',
					Descripcion VARCHAR(255) '$.Descripcion',
					Fecha_Celebracion DATETIME '$.Fecha_Celebracion',
					Precio DECIMAL(6,2) '$.Precio',
					Aforo INT '$.Aforo',
					Foto NVARCHAR(MAX) '$.Foto',
					Id_Empresa INT '$.Empresa.Id')



			-- Comprobaciones de que los campos obligatorios tienen informacion

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
					SET @MENSAJE = 'No hay Id de empresa' 
					SET @JSON_OUT = '{"Exito":false}'
				END
			

			-- Comrpobaciones de que no exista la empresa y ciertas comprobaciones de validaciones 

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
							SET @RETCODE = 7
							SET @MENSAJE = 'Empresa no existente o eliminada logicamente'
							SET @JSON_OUT = '{"Exito":false}'
						END
			
		
				END

				IF (@RETCODE = 0)
					BEGIN
						SET @JSON_PRUEBA = NULL
						SET @JSON_PRUEBA = (
							SELECT e.*
							FROM Experiencia e
							WHERE	e.Aforo = @AFORO AND
									e.Descripcion = @DESCRIPCION AND
									e.Fecha_Celebracion = @FECHA_CELEBRACION AND
									e.Foto = @FOTO AND
									e.Id_Empresa = @ID_EMPRESA AND
									e.Precio = @PRECIO AND
									e.Titulo = @TITULO AND
									e.Eliminado = 0
						FOR JSON AUTO)

						IF (@JSON_PRUEBA IS NOT NULL)
							BEGIN
								SET @RETCODE = 8
								SET @MENSAJE = 'Ya existe una experiencia identica'
							END
					END



			SET NOCOUNT ON;

			if (@RETCODE = 0)
				BEGIN

					insert into Experiencia
						(
						Titulo,
						Descripcion,
						Fecha_Celebracion,
						Precio,
						Aforo,
						Foto,
						Id_Empresa,
						Eliminado,
						Borrado_Solicitado
						) 
					values 
						(
						@TITULO,
						@DESCRIPCION,
						@FECHA_CELEBRACION,
						@PRECIO,
						@AFORO,
						@FOTO,
						@ID_EMPRESA,
						0,
						0
						)
			
				SET @JSON_OUT = '{"Exito":true}'

				END
			ELSE
				BEGIN
					SET @JSON_OUT = '{"Exito":false}'
				END
		
		COMMIT TRANSACTION

		

	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000) + ' | ' + @JSON_IN
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
		ROLLBACK TRANSACTION
	END CATCH
		