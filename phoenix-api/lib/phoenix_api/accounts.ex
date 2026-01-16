defmodule PhoenixApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias PhoenixApi.Repo

  alias PhoenixApi.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(params \\ %{}) do
    import Ecto.Query
    alias PhoenixApi.Repo
    alias PhoenixApi.Accounts.User

    query =
      from u in User,
        where: true

    query =
      query
      |> maybe_ilike(:first_name, Map.get(params, "first_name"))
      |> maybe_ilike(:last_name, Map.get(params, "last_name"))
      |> maybe_gender(Map.get(params, "gender"))
      |> maybe_birthdate_range(Map.get(params, "birthdate_from"), Map.get(params, "birthdate_to"))
      |> apply_sort(params)

    Repo.all(query)
  end

  defp maybe_ilike(query, _field, nil), do: query
  defp maybe_ilike(query, _field, ""), do: query
  defp maybe_ilike(query, field, value) do
    import Ecto.Query
    where(query, [u], ilike(field(u, ^field), ^"%#{value}%"))
  end

  defp maybe_gender(query, nil), do: query
  defp maybe_gender(query, ""), do: query
  defp maybe_gender(query, gender) when gender in ["male", "female"] do
    import Ecto.Query
    atom = String.to_atom(gender)
    where(query, [u], u.gender == ^atom)
  end
  defp maybe_gender(query, _), do: query

  defp maybe_birthdate_range(query, from_s, to_s) do
    import Ecto.Query
    from_date = parse_date(from_s)
    to_date = parse_date(to_s)

    cond do
      from_date && to_date -> where(query, [u], u.birthdate >= ^from_date and u.birthdate <= ^to_date)
      from_date -> where(query, [u], u.birthdate >= ^from_date)
      to_date -> where(query, [u], u.birthdate <= ^to_date)
      true -> query
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil
  defp parse_date(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp apply_sort(query, %{"sort" => sort, "dir" => dir}) do
    import Ecto.Query
    dir = if dir in ["desc", "DESC"], do: :desc, else: :asc

    allowed = %{
      "first_name" => :first_name,
      "last_name" => :last_name,
      "birthdate" => :birthdate,
      "gender" => :gender,
      "inserted_at" => :inserted_at
    }

    case Map.get(allowed, sort) do
      nil -> query
      field_atom -> order_by(query, [u], [{^dir, field(u, ^field_atom)}])
    end
  end

  defp apply_sort(query, _), do: query

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
