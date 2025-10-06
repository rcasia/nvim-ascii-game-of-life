-- Importar los módulos necesarios
local ui = require("ascii-ui")
local useState = ui.hooks.useState
local useInterval = ui.hooks.useInterval

local Button = ui.components.Button
local Paragraph = ui.components.Paragraph

local Hexacolor = require("ascii-ui.hexacolor")

local range = vim.fn.range

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
			grid[i][j] = 0
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

local function useGrid()
	local grid, setGrid = useState(create_grid())

	local function updateGrid()
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
	end

	local toggleCell = function(row, col)
		local new_grid = vim.deepcopy(grid)
		new_grid[row][col] = 1 - new_grid[row][col] -- Alterna entre 0 y 1
		setGrid(new_grid)
	end

	return grid, updateGrid, toggleCell
end

-- El componente principal del juego
local GameOfLife = ui.createComponent("GameOfLife", function()
	-- Estado de la cuadrícula
	local grid, updateGrid, toggleCell = useGrid()
	local started, setStarted = useState(false)
	local speed, setSpeed = useState(5)
	local config = ui.hooks.useConfig()
	local cc = config.characters

	useInterval(function()
		updateGrid()
	end, started and math.floor(1000 / speed) or nil)

	-- Renderizado de la cuadrícula
	-- Se devuelve una lista de bufferlines, una por cada fila de la cuadrícula
	return {
		Button({
			label = started and "Pause" or "Start",
			on_press = function()
				setStarted(not started)
			end,
		}),
		Button({
			label = speed .. "x",
			on_press = function()
				setSpeed(speed % 10 + 1)
			end,
		}),
		vim.iter(range(1, ROWS))
			:map(function(row_index)
				-- Se crea un iterador para las columnas de la fila actual
				local segments = vim.iter(range(1, COLS))
					:map(function(col_index)
						-- Devuelve un objeto Segment para cada carácter
						return ui.blocks.Segment({
							content = grid[row_index][col_index] == 1 and cc.thumb or cc.whitespace,
							is_focusable = not started,
							color = { fg = "#FF0000" },
							interactions = {
								SELECT = function()
									print(("i am (%d, %d)"):format(row_index, col_index))
									toggleCell(row_index, col_index)
								end,
							},
						})
					end)
					:totable()

				-- Agrupa los segmentos en un Bufferline y lo devuelve
				return ui.blocks.Bufferline(unpack(segments))
			end)
			:totable(),
	}
end)

local App = ui.createComponent("App", function()
	return {
		Paragraph({ content = "Conway's Game of Life - Press 'q' to exit" }),
		GameOfLife(),
	}
end)

-- Montar la aplicación
ui.mount(App)
