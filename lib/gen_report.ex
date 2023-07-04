defmodule GenReport do
  @moduledoc """
    Gerar relatórios

    Dez pessoas freelancers trabalharam para a empresa X por cinco anos, e o histórico com todos os dados
    de cada uma dessas pessoas (nome, horas trabalhadas, dia, mês e ano) foi transferido para um arquivo CSV
    na seguinte ordem: nome, horas do dia (que variam de 1 a 8 horas), dia (que varia de 1 a 30, inclusive para o mês de fevereiro, sem considerar anos bissextos),
    mês e ano (que variam de 2016 a 2020).
    Resumindo: ** nome **, ** número de horas **, ** dia **, ** mês ** e ** ano **.

    Fornece a função build/1 para ler e converter o arquivo em uma lista.
  """

  alias GenReport.Parser

  @available_members [
    "daniele",
    "mayk",
    "giuliano",
    "cleiton",
    "jakeliny",
    "joseph",
    "danilo",
    "diego",
    "cleiton",
    "rafael",
    "vinicius"
  ]

  @available_months %{
    1 => "janeiro",
    2 => "fevereiro",
    3 => "março",
    4 => "abril",
    5 => "maio",
    6 => "junho",
    7 => "julho",
    8 => "agosto",
    9 => "setembro",
    10 => "outubro",
    11 => "novembro",
    12 => "dezembro"
  }

  @available_years [
    2016,
    2017,
    2018,
    2019,
    2020
  ]

  @doc """
  Gerar relatório

  ## Parâmetros
    - fileName: String do arquivo a ser lido
  """
  def build(fileName) do
    result =
      fileName
      |> Parser.parse_file()
      |> Enum.reduce(report_acc(), fn line, report -> gen_report(line, report) end)

    {:ok, result}
  end

  def build, do: {:error, "Insira o nome de um arquivo"}

  def build_from_many do
    {:error, "Forneça uma lista de strings"}
  end

  def build_from_many(file_names) when not is_list(file_names) do
    {:error, "Forneça uma lista de strings"}
  end

  @doc """
  Processar vários arquivos assincronamente
  """
  def build_from_many(file_names) do
    result =
      file_names
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, {:ok, result}}, report ->
        sum_reports(report, result)
      end)

    {:ok, result}
  end

  defp gen_report([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    new_name = String.downcase(name)

    # Gerar o mapa all_hours
    all_hours = gen_all_hours(all_hours, new_name, hours)

    # Gerar o mapa hours_per_month
    hours_per_month = gen_hours_per_month(hours_per_month, new_name, hours, month)

    # Gerar o mapa hours_per_year
    hours_per_year = gen_hours_per_year(hours_per_year, new_name, hours, year)

    # Construir o relatório final
    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp gen_all_hours(all_hours, name, hours) do
    Map.update(all_hours, name, hours, &(&1 + hours))
  end

  defp gen_hours_per_month(hours_per_month, name, hours, month) do
    calc_hours_month =
      Map.update(hours_per_month, name, %{}, fn curr ->
        Map.update(curr, @available_months[month], hours, &(&1 + hours))
      end)

    %{hours_per_month | name => calc_hours_month}
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)
    hours_per_month = merge_maps(hours_per_month1, hours_per_month2)
    hours_per_year = merge_maps(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> calc_merge_maps(value1, value2) end)
  end

  defp calc_merge_maps(val1, val2) when is_map(val1) and is_map(val2) do
    merge_maps(val1, val2)
  end

  defp calc_merge_maps(val1, val2) do
    val1 + val2
  end

  defp gen_hours_per_year(hours_per_year, name, hours, year) do
    calc_hours_year =
      Map.update(hours_per_year, name, %{}, fn curr ->
        Map.update(curr, year, hours, &(&1 + hours))
      end)

    %{hours_per_year | name => calc_hours_year}
  end

  defp report_acc do
    all_hours = Enum.into(@available_members, %{}, &{&1, 0})
    hours_per_month = Enum.into(@available_members, %{}, &{&1, report_acc_month()})
    hours_per_year = Enum.into(@available_members, %{}, &{&1, report_acc_years()})
    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp report_acc_month do
    @available_months
    |> Map.values()
    |> Enum.into(%{}, &{&1, 0})
  end

  defp report_acc_years do
    @available_years
    |> Enum.into(%{}, &{&1, 0})
  end

  defp build_report(all_hours, hours_per_month, hours_per_year),
    do: %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
end
