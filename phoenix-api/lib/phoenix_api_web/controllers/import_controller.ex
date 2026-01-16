defmodule PhoenixApiWeb.ImportController do
  use PhoenixApiWeb, :controller

  alias PhoenixApi.Import.PeselImporter

  def run(conn, _params) do
    token = get_req_header(conn, "x-import-token") |> List.first()
    expected = System.get_env("IMPORT_TOKEN")

    if expected && token == expected do
      :ok = PeselImporter.run!()
      json(conn, %{status: "ok"})
    else
      conn |> put_status(:unauthorized) |> json(%{error: "unauthorized"})
    end
  end
end
