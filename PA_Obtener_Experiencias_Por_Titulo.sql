USE [MeetFever]
GO
/****** Object:  StoredProcedure [dbo].[PA_Obtener_Experiencias_Por_Titulo]    Script Date: 15/06/2022 11:13:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================
-- Author: Alberto Horcajada
-- Create date: 24/04/2022
-- Descrption: Este es un procedimiento almacenado que devuelve todos los datos de una experiencia dado un título
-- ============================================

	ALTER PROCEDURE [dbo].[PA_Obtener_Experiencias_Por_Titulo]
	
		@JSON_IN NVARCHAR(MAX), 
		@JSON_OUT NVARCHAR(MAX) OUTPUT,
		@INVOKER INT,
		@RETCODE INT OUTPUT,
		@MENSAJE NVARCHAR(MAX) OUTPUT

	AS
		SET @RETCODE = 0
		SET @MENSAJE = 'Experiencias encontradas'
		DECLARE @TITULO VARCHAR(50)

		DECLARE @JSONPRUEBA NVARCHAR(MAX)

		-- Recuperacion del Titulo del JSON entrante
	BEGIN TRY

		SELECT @TITULO = Titulo
			FROM
				OPENJSON (@JSON_IN) WITH (Titulo VARCHAR(50) '$.Titulo')
		-- Comrpobaciones de ese titulo
		
		IF (@TITULO IS NULL)
			BEGIN
				SET @RETCODE = 1
				SET @MENSAJE = 'Titulo nulo'
				SET @JSON_OUT = '{"Exito":false}'
			END

		ELSE IF (@TITULO = '')
			BEGIN
				SET @RETCODE = 2
				SET @MENSAJE = 'Titulo vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END

		SET NOCOUNT ON;

		-- Crear JSON de respuesta a raiz de la consulta
	IF (@RETCODE = 0)
	BEGIN
		SET @JSON_OUT = (
			
			SELECT e.Id,
			e.Titulo,
			e.Descripcion,
			e.Fecha_Celebracion,
			e.Precio,
			e.Aforo,
			e.Foto,
			-- Como una Experiencia contiene una empresa le tengo que mandar el objeto de la empresa
			u.id AS 'Empresa.Id',
			u.Correo AS 'Empresa.Correo',
			u.Contrasena AS 'Empresa.Contrasena',
			u.Nick AS 'Empresa.Nick',
			u.Foto_Fondo AS 'Empresa.Foto_Fondo',
			u.Foto_Perfil AS 'Empresa.Foto_Perfil',
			u.Telefono AS 'Empresa.Telefono',
			u.Frase AS 'Empresa.Frase',
			em.Nombre_Empresa AS 'Empresa.Nombre_Empresa', 
			em.Cif AS 'Empresa.Cif', 
			em.Direccion_Facturacion AS 'Empresa.Direccion_Facturacion', 
			em.Direccion_Fiscal AS 'Empresa.Direccion_Fiscal', 
			em.Nombre_Persona AS 'Empresa.Nombre_Persona', 
			em.Apellido1_Persona AS 'Empresa.Apellido1_Persona', 
			em.Apellido2_Persona AS 'Empresa.Apellido2_Persona',
			em.Dni_Persona AS 'Empresa.Dni_Persona'

			FROM Experiencia e INNER JOIN Empresa em on (e.Id_Empresa = em.Id) INNER JOIN Usuario u ON (u.Id = em.Id)
			WHERE e.Titulo LIKE @TITULO + '%' and e.eliminado = 0
			FOR JSON PATH)


		-- Dos comprobaciones para asegurarnos de que está bien el JSON

		IF (@JSON_OUT = '')
			BEGIN
				SET @RETCODE = 3
				SET @MENSAJE = 'JSON vacio'
				SET @JSON_OUT = '{"Exito":false}'
			END


		IF(@JSON_OUT IS NULL)
			BEGIN
				SET @RETCODE = 4
				SET @MENSAJE = 'Experiencias no encontradas'
				SET @JSON_OUT = '{"Exito":false}'
			END
		
	END
	END TRY
	BEGIN CATCH
		SET @MENSAJE = SUBSTRING(ERROR_MESSAGE(), 1, 8000)
		SET @RETCODE = -1
		SET @JSON_OUT = '{"Exito":false}'
	END CATCH
