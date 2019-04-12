defmodule BearNecessitiesWeb.Game do
  use Phoenix.LiveView
  require Logger

  alias BearNecessitiesWeb.Playfield

  def render(assigns) do
    Playfield.render("template.html", assigns)
  end

  def mount(_session, %{id: id} = socket) do
    bear = Player.start("fatboypunk", id)
    field = Game.get_field(id)

    socket =
      socket
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:field, field)

    {:ok, socket}
  end

  def handle_event(_, "Meta", socket) do
    {:noreply, socket}
  end

  def handle_event("key_move", key, %{id: id} = socket) do
    key
    |> IO.inspect(label: "key")

    bear = Player.move(id, move_to(key))

    socket =
      socket
      |> update(:pos_x, fn _ -> bear.pos_x end)
      |> update(:pos_y, fn _ -> bear.pos_y end)

    {:noreply, socket}
  end

  def move_to("ArrowRight"), do: :right_arrow
  def move_to("ArrowLeft"), do: :left_arrow
  def move_to("ArrowUp"), do: :up_arrow
  def move_to("ArrowDown"), do: :down_arrow
end
