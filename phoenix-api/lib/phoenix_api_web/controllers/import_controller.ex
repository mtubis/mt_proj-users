defmodule PhoenixApiWeb.ImportController do
  use PhoenixApiWeb, :controller

  alias PhoenixApi.Import.PeselImporter

  def run(conn, _params) do
    token = get_req_header(conn, "x-import-token") |> List.first()
    expected = System.get_env("IMPORT_TOKEN")

    cond do
      expected && token != expected ->
        conn |> put_status(:unauthorized) |> json(%{error: "unauthorized"})

      true ->
        try do
          :ok = PeselImporter.run!()
          json(conn, %{status: "ok"})
        rescue
          e ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: Exception.message(e)})
        end
    end
  end
end
