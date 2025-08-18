require_relative '../../lib/ocr_parser'
require 'open3'
require 'securerandom'

class PdfsController < ApplicationController
  def new
  end
  # Método para processar o upload do PDF e extrair o texto usando OCR
  def create
    uploaded_file = params[:pdf_file]

    unless uploaded_file
      flash[:alert] = "Nenhum arquivo enviado."
      redirect_to new_pdf_path and return
    end

    unique_id = SecureRandom.hex(4)
    pdf_path   = Rails.root.join('tmp', "upload_#{unique_id}.pdf")
    image_path = Rails.root.join('tmp', "page_#{unique_id}")

    File.open(pdf_path, 'wb') { |f| f.write(uploaded_file.read) }

    cmd_pdftoppm = "pdftoppm -png -singlefile -r 300 \"#{pdf_path}\" \"#{image_path}\""
    stdout1, stderr1, status1 = Open3.capture3(cmd_pdftoppm)

    unless status1.success?
      File.delete(pdf_path) if File.exist?(pdf_path)
      flash[:alert] = "Erro na conversão do PDF: #{stderr1}"
      redirect_to new_pdf_path and return
    end

    raw_image = "#{image_path}.png"
    cleaned_image = "#{image_path}_cleaned.png"

    cmd_convert = "convert \"#{raw_image}\" -resize 150% -colorspace Gray -contrast -sharpen 0x1 -threshold 60% \"#{cleaned_image}\""
    stdout2, stderr2, status2 = Open3.capture3(cmd_convert)

    unless status2.success?
      File.delete(pdf_path) if File.exist?(pdf_path)
      File.delete(raw_image) if File.exist?(raw_image)
      flash[:alert] = "Erro no pós-processamento da imagem: #{stderr2}"
      redirect_to new_pdf_path and return
    end

    ocr = RTesseract.new(cleaned_image, lang: 'por', psm: 4)
    texto_extraido = ocr.to_s.strip

    debug_ocr_path = Rails.root.join('tmp', "ocr_debug_#{unique_id}.txt")
    File.write(debug_ocr_path, texto_extraido)

    if texto_extraido.empty?
      flash[:alert] = "OCR não conseguiu extrair texto. Tente outro PDF ou ajuste a qualidade."
      File.delete(pdf_path)   if File.exist?(pdf_path)
      File.delete(raw_image)  if File.exist?(raw_image)
      File.delete(cleaned_image) if File.exist?(cleaned_image)
      redirect_to new_pdf_path and return
    end

    # 6️⃣ Salva OCR no banco
    @pdf = Pdf.new(
      nome_arquivo: uploaded_file.original_filename,
      ocr_text: texto_extraido
    )

    if @pdf.save
      # Remove arquivos temporários mas mantém o TXT debug
      File.delete(pdf_path)   if File.exist?(pdf_path)
      File.delete(raw_image)  if File.exist?(raw_image)
      File.delete(cleaned_image) if File.exist?(cleaned_image)

      redirect_to pdf_path(@pdf)
    else
      flash[:alert] = "Erro ao salvar o texto OCR."
      File.delete(pdf_path)   if File.exist?(pdf_path)
      File.delete(raw_image)  if File.exist?(raw_image)
      File.delete(cleaned_image) if File.exist?(cleaned_image)
      redirect_to new_pdf_path
    end
  end

  def show
    @pdf = Pdf.find(params[:id])
    @text = @pdf.ocr_text

    parser = OcrParser.new(@text)
    @alunos = parser.parse_alunos

    # Debug: imprime no log do servidor
    Rails.logger.debug("[OCR DEBUG] Texto completo:\n#{@text}")
    Rails.logger.debug("[OCR DEBUG] Alunos extraídos:\n#{@alunos.inspect}")
  end
end
