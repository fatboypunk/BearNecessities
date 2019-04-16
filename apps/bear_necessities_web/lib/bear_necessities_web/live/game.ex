defmodule BearNecessitiesWeb.Game do
  use Phoenix.LiveView
  require Logger

  @action_keys ["ArrowRight", "ArrowLeft", "ArrowUp", "ArrowDown"]

  alias BearNecessitiesWeb.Playfield

  def render(assigns) do
    Playfield.render("template.html", assigns)
  end

  def mount(_session, %{id: id} = socket) do
    field = Game.get_field(id)
    players = Game.get_players()

    socket =
      socket
      |> assign(:id, id)
      |> assign(:viewport, [])
      |> assign(:pos_x, nil)
      |> assign(:pos_y, nil)
      |> assign(:field, field)
      |> assign(:players, players)
      |> assign(:bear, %Bear{started: false})

    {:ok, socket}
  end

  def handle_event("start", %{"player" => %{"display_name" => display_name}}, %{id: id} = socket) do
    if connected?(socket), do: :timer.send_interval(50, self(), :update)

    bear = Player.start(display_name, id)
    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:id, id)
      |> assign(:viewport, viewport)
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:bear, bear)

    {:noreply, socket}
  end

  def handle_event(_, "Meta", socket) do
    {:noreply, socket}
  end

  def handle_event("key_move", key, %{id: id} = socket)
      when key in @action_keys do
    bear = Player.move(id, move_to(key))

    viewport = ViewPort.get_viewport(id)

    socket =
      socket
      |> assign(:pos_x, bear.pos_x)
      |> assign(:pos_y, bear.pos_y)
      |> assign(:viewport, viewport)

    {:noreply, socket}
  end

  def handle_event("key_move", _, %{id: id} = socket) do
    Player.claw(id)
    {:noreply, socket}
  end

  def handle_event("claw", " ", %{id: id} = socket) do
    Player.claw(id)
    {:noreply, socket}
  end

  def handle_event("claw", _, %{id: id} = socket) do
    {:noreply, socket}
  end

  def handle_info(:update, %{id: id, assigns: %{bear: %Bear{dead: nil}}} = socket) do
    players = Game.get_players()
    viewport = ViewPort.get_viewport(id)
    bear = Game.get_bear(id)

    socket =
      socket
      |> assign(:viewport, viewport)
      |> assign(:players, players)
      |> assign(:bear, bear)

    {:noreply, socket}
  end

  def handle_info(:update, %{id: id, assigns: %{bear: %Bear{dead: dead} = bear}} = socket)
      when dead > 0 do
    IO.inspect(dead)
    {:noreply, update(socket, :bear, fn bear -> %{bear | dead: bear.dead - 51} end)}
  end

  def handle_info(:update, %{id: id, assigns: %{bear: %Bear{dead: dead} = bear}} = socket)
      when dead < 50 do
    Game.remove_bear(id)
    {:noreply, update(socket, :bear, fn bear -> %{bear | started: false, dead: nil} end)}
  end

  def terminate(reason, %{id: id} = socket) do
    Game.remove_bear(id)

    reason
  end

  def move_to("ArrowRight"), do: :right_arrow
  def move_to("ArrowLeft"), do: :left_arrow
  def move_to("ArrowUp"), do: :up_arrow
  def move_to("ArrowDown"), do: :down_arrow
end
