-- Importar los módulos necesarios
local ui = require("ascii-ui")
local useState = ui.hooks.useState
local useInterval = ui.hooks.useInterval

local Button = ui.components.Button
local Paragraph = ui.components.Paragraph

-- Dimensiones de la cuadrícula
local ROWS = 40
local COLS = 100

-- Funciones auxiliares
local function create_grid()
	local grid = {}
	for i = 1, ROWS do
		grid[i] = {}
		for j = 1, COLS do
			-- Inicializar la cuadrícula con un patrón aleatorio de células vivas o muertas
			grid[i][j] = (math.random(10) > 8) and 1 or 0
		end
	end
	return grid
end

local function count_neighbors(grid, row, col)
	local live_neighbors = 0
	for i = -1, 1 do
		for j = -1, 1 do
			if i ~= 0 or j ~= 0 then
				local neighbor_row, neighbor_col = row + i, col + j
				-- Comprobación de límites y suma de vecinos vivos
				if neighbor_row >= 1 and neighbor_row <= ROWS and neighbor_col >= 1 and neighbor_col <= COLS then
					live_neighbors = live_neighbors + grid[neighbor_row][neighbor_col]
				end
			end
		end
	end
	return live_neighbors
end

-- El componente principal del juego
local GameOfLife = ui.createComponent("GameOfLife", function(props)
	-- Estado de la cuadrícula
	local grid, setGrid = useState(create_grid())
	local config = ui.hooks.useConfig()

	useInterval(function()
		local new_grid = {}
		for i = 1, ROWS do
			new_grid[i] = {}
			for j = 1, COLS do
				local neighbors = count_neighbors(grid, i, j)
				local is_alive = grid[i][j] == 1

				if is_alive and (neighbors == 2 or neighbors == 3) then
					new_grid[i][j] = 1 -- Sobrevive
				elseif not is_alive and neighbors == 3 then
					new_grid[i][j] = 1 -- Nace
				else
					new_grid[i][j] = 0 -- Muere
				end
			end
		end
		setGrid(new_grid)
	end, props.started and 100 or nil)

	-- Renderizado de la cuadrícula
	-- Se devuelve una lista de bufferlines, una por cada fila de la cuadrícula
	local lines = {}
	for i = 1, ROWS do
		local line_content = ""
		for j = 1, COLS do
			if grid[i][j] == 1 then
				line_content = line_content .. config.characters.thumb -- Célula viva
			else
				line_content = line_content .. config.characters.whitespace -- Célula muerta
			end
		end
		table.insert(lines, line_content)
	end

	return vim.iter(lines)
		:map(function(line)
			return ui.blocks.Segment({ content = line }):wrap()
		end)
		:totable()
end, { started = "boolean" })

local App = ui.createComponent("App", function()
	local started, setStarted = useState(true)

	return {
		GameOfLife({ started = started }),
		Paragraph({ content = "Conway's Game of Life - Press 'q' to exit" }),
		Button({
			label = started and "Pause" or "Start",
			on_press = function()
				setStarted(not started)
			end,
		}),
	}
end)

-- Montar la aplicación
ui.mount(App)
