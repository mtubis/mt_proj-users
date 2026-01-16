defmodule PhoenixApi.Import.PeselImporter do
  alias PhoenixApi.Accounts
  alias PhoenixApi.Repo

  require Logger

  @api_base "https://api.dane.gov.pl/1.4"

  def run!() do
    firstnames_dataset_id = System.fetch_env!("PESEL_FIRSTNAMES_DATASET_ID")
    surnames_dataset_id = System.fetch_env!("PESEL_SURNAMES_DATASET_ID")

    male_names = top100_first_names!(firstnames_dataset_id, :male)
    female_names = top100_first_names!(firstnames_dataset_id, :female)

    male_surnames = top100_surnames!(surnames_dataset_id, :male)
    female_surnames = top100_surnames!(surnames_dataset_id, :female)

    users =
      1..100
      |> Enum.map(fn _ ->
        if :rand.uniform(2) == 1 do
          %{
            "gender" => "male",
            "first_name" => Enum.random(male_names),
            "last_name" => Enum.random(male_surnames),
            "birthdate" => random_birthdate_iso()
          }
        else
          %{
            "gender" => "female",
            "first_name" => Enum.random(female_names),
            "last_name" => Enum.random(female_surnames),
            "birthdate" => random_birthdate_iso()
          }
        end
      end)

    Repo.transaction(fn ->
      Enum.each(users, fn attrs ->
        case Accounts.create_user(attrs) do
          {:ok, _} -> :ok
          {:error, cs} -> Repo.rollback(cs)
        end
      end)
    end)

    :ok
  end

  # -------------------------
  # Selection logic
  # -------------------------

  defp top100_first_names!(dataset_id, gender) when gender in [:male, :female] do
    gender_regex =
      case gender do
        :male -> ~r/imion.*m(e|ę)sk/i
        :female -> ~r/imion.*(z|ż)e(n|ń)sk/i
      end

    attrs_list =
      list_dataset_resources!(dataset_id)
      |> Enum.map(& &1["attributes"])
      |> Enum.filter(fn attrs ->
        title = attrs["title"] || ""
        Regex.match?(gender_regex, title)
      end)

    if attrs_list == [] do
      raise "Nie znaleziono żadnych zasobów imion dla gender=#{gender} w dataset #{dataset_id}"
    end

    # We don't want a “middle name.”
    attrs_list =
      attrs_list
      |> Enum.reject(fn attrs ->
        title = attrs["title"] || ""
        Regex.match?(~r/imi[eę]\s+drugie/i, title)
      end)

    if attrs_list == [] do
      raise "Znaleziono tylko zasoby 'imię drugie' dla gender=#{gender} w dataset #{dataset_id}"
    end

    # Prefer “first name” if it is in the title, but do not require it.
    preferred =
      attrs_list
      |> Enum.filter(fn attrs ->
        title = attrs["title"] || ""
        Regex.match?(~r/imi[eę]\s+pierwsze/i, title)
      end)

    chosen = newest_by_modified(preferred != [] && preferred || attrs_list)
    csv_url = csv_url_from_attrs(chosen)

    Logger.info("Chosen FIRST NAMES title=#{chosen["title"]}")
    Logger.info("Using CSV: #{csv_url}")

    csv = fetch_text!(csv_url)
    parse_top100_from_csv(csv)
  end

  defp top100_surnames!(dataset_id, gender) when gender in [:male, :female] do
    gender_regex =
      case gender do
        :male -> ~r/nazwisk.*m(e|ę)sk/i
        :female -> ~r/nazwisk.*(z|ż)e(n|ń)sk/i
      end

    attrs_list =
      list_dataset_resources!(dataset_id)
      |> Enum.map(& &1["attributes"])
      |> Enum.filter(fn attrs ->
        title = attrs["title"] || ""
        Regex.match?(gender_regex, title)
      end)

    if attrs_list == [] do
      raise "Nie znaleziono żadnych zasobów nazwisk dla gender=#{gender} w dataset #{dataset_id}"
    end

    chosen = newest_by_modified(attrs_list)
    csv_url = csv_url_from_attrs(chosen)

    Logger.info("Chosen SURNAMES title=#{chosen["title"]}")
    Logger.info("Using CSV: #{csv_url}")

    csv = fetch_text!(csv_url)
    parse_top100_from_csv(csv)
  end

  defp newest_by_modified(attrs_list) do
    attrs_list
    |> Enum.sort_by(fn attrs -> attrs["modified"] || attrs["created"] || "" end, :desc)
    |> List.first()
  end

  # -------------------------
  # dane.gov.pl API + CSV URL extraction
  # -------------------------

  defp list_dataset_resources!(dataset_id) do
    url = "#{@api_base}/datasets/#{dataset_id}/resources"
    resp = Req.get!(url)
    resp.body["data"] || []
  end

  defp csv_url_from_attrs(attrs) do
    attrs["csv_download_url"] ||
      attrs["csv_file_url"] ||
      csv_from_file_url(attrs["file_url"]) ||
      csv_from_files(attrs["files"]) ||
      raise("Brak URL do CSV w zasobie: #{inspect(attrs)}")
  end

  defp csv_from_file_url(nil), do: nil

  defp csv_from_file_url(url) when is_binary(url) do
    if String.ends_with?(url, ".csv"), do: url, else: nil
  end

  defp csv_from_files(nil), do: nil

  defp csv_from_files(files) when is_list(files) do
    files
    |> Enum.find(fn f -> (f["format"] || f[:format]) == "csv" end)
    |> case do
      nil -> nil
      f -> f["download_url"] || f[:download_url]
    end
  end

  defp fetch_text!(url) do
    resp = Req.get!(url)
    if is_binary(resp.body), do: resp.body, else: to_string(resp.body)
  end

  # -------------------------
  # CSV parsing + data generation
  # -------------------------

  defp parse_top100_from_csv(csv) do
    lines = String.split(csv, ["\r\n", "\n"], trim: true)

    # remove header
    data_lines = Enum.drop(lines, 1)

    data_lines
    |> Enum.map(&first_csv_col/1)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.trim(&1, "\""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.take(100)
  end

  defp first_csv_col(line) do
    cond do
      String.contains?(line, ";") -> line |> String.split(";", parts: 2) |> hd()
      String.contains?(line, ",") -> line |> String.split(",", parts: 2) |> hd()
      true -> line
    end
  end

  defp random_birthdate_iso() do
    from = ~D[1970-01-01]
    to = ~D[2024-12-31]
    days = Date.diff(to, from)
    Date.add(from, :rand.uniform(days + 1) - 1) |> Date.to_iso8601()
  end
end
