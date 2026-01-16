defmodule PhoenixApi.Import.PeselImporter do
  require Logger

  @api_base "https://api.dane.gov.pl/1.4"

  def run!() do
    dataset_id = System.fetch_env!("PESEL_FIRSTNAMES_DATASET_ID")
    url = "#{@api_base}/datasets/#{dataset_id}/resources"

    resp = Req.get!(url)

    Logger.info("dane.gov.pl status=#{resp.status}")
    Logger.info("body keys=#{inspect(Map.keys(resp.body))}")

    # pokaż 1 zasób, żeby zobaczyć gdzie jest download_url
    first =
      resp.body["data"]
      |> List.first()

    Logger.info("first resource sample=#{inspect(first)}")

    :ok
  end
end
