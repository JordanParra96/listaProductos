import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class Producto {
  int? id;
  String descripcion;
  double precio;
  String categoria;
  bool activo;
  String observacion;

  Producto({
    this.id,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.activo,
    required this.observacion,
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      descripcion: map['descripcion'],
      precio:
          map['precio'] is int
              ? (map['precio'] as int).toDouble()
              : map['precio'],
      categoria: map['categoria'],
      activo: map['activo'] == 1, // Se almacena 1 o 0 en la BD
      observacion: map['observacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'activo': activo ? 1 : 0, // Guardar como entero
      'observacion': observacion,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Obtiene la ruta base para las BD en Android/iOS
    final dbPath = await getDatabasesPath();
    // Une la ruta con el nombre de tu archivo .db
    final path = p.join(dbPath, 'productos.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT,
        precio REAL,
        categoria TEXT,
        activo INTEGER,
        observacion TEXT
      )
    ''');
    await db.insert('productos', {
      'descripcion': 'Memoria USB',
      'precio': 43000,
      'categoria': 'Almacenamiento',
      'activo': 1,
      'observacion': 'Quedan 5 unidades',
    });
  }

  Future<int> insertProducto(Producto producto) async {
    final db = await database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> getProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');
    return maps.map((map) => Producto.fromMap(map)).toList();
  }
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Producto>> _futureProductos;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  void _loadProductos() {
    setState(() {
      _futureProductos = DatabaseHelper().getProductos();
    });
  }

  void _navigateToAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage()),
    );
    _loadProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listado de Productos')),
      body: FutureBuilder<List<Producto>>(
        future: _futureProductos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final productos = snapshot.data ?? [];
            if (productos.isEmpty) {
              return const Center(child: Text('No hay productos.'));
            }
            return ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return ListTile(
                  title: Text(producto.descripcion),
                  subtitle: Text(
                    'Precio: \$${producto.precio.toStringAsFixed(2)}\n'
                    'Categoría: ${producto.categoria}\n'
                    'Observación: ${producto.observacion}',
                  ),
                  trailing: Icon(
                    producto.activo
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: producto.activo ? Colors.green : null,
                  ),
                  isThreeLine: true,
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _navigateToAddProduct,
      ),
    );
  }
}

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores o variables para cada campo
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  String _categoriaSeleccionada = 'Almacenamiento';
  bool _activo = false;
  final _observacionController = TextEditingController();

  // Lista de categorías para el Dropdown
  final List<String> _categorias = [
    'Almacenamiento',
    'Audio',
    'Video',
    'Accesorios',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del producto',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Precio
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items:
                    _categorias.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value ?? 'Almacenamiento';
                  });
                },
              ),
              const SizedBox(height: 16),
              // Activo
              CheckboxListTile(
                title: const Text('Activo'),
                value: _activo,
                onChanged: (value) {
                  setState(() {
                    _activo = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Observación
              TextFormField(
                controller: _observacionController,
                decoration: const InputDecoration(labelText: 'Observación'),
              ),
              const SizedBox(height: 16),
              // Botón Guardar
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Crear objeto Producto
                    final nuevoProducto = Producto(
                      descripcion: _descripcionController.text,
                      precio: double.parse(_precioController.text),
                      categoria: _categoriaSeleccionada,
                      activo: _activo,
                      observacion: _observacionController.text,
                    );
                    // Insertar en la BD
                    await DatabaseHelper().insertProducto(nuevoProducto);
                    // Regresar a la pantalla anterior
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Productos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductListPage(),
    );
  }
}
