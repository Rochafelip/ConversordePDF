class OcrParser
  # Regex mais permissivo para matrícula: aceita hífen ou espaço entre partes, ignora case
  MATRICULA_REGEX = /20\d{2}[-\s]?IP[-\s]?\d{4}/i

  def initialize(texto)
    # remover tudo antes da primeira matrícula, se houver
    primeiro = texto.index(MATRICULA_REGEX)
    @texto = primeiro ? texto[primeiro..-1] : texto
  end

  def parse_alunos
    blocos = @texto.split(/(?=#{MATRICULA_REGEX})/)
    alunos = []

    blocos.each do |bloco|
      next unless bloco =~ MATRICULA_REGEX

      matricula_raw = bloco[MATRICULA_REGEX]
      matricula = matricula_raw.upcase.gsub(/\s+/, '-')

      nome = bloco.sub(MATRICULA_REGEX, '').gsub(/[^a-zA-ZÀ-ÿ\s]/, ' ').squeeze(' ').strip

      next if nome.length < 5

      alunos << { matricula: matricula, nome: nome }
    end

    alunos
  end
end
