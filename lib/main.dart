import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa la base de datos
  final database = await openDatabase(
    join(await getDatabasesPath(), 'productos_database.db'),
    onCreate: (db, version) async {
      // Crear la tabla "productos"
      await db.execute('CREATE TABLE productos(name TEXT PRIMARY KEY)');
      // Pre-cargar la tabla con los productos
      await db.insert('productos', {'name': 'manzana'});
      await db.insert('productos', {'name': 'pera'});
      await db.insert('productos', {'name': 'mango'});
    },
    version: 1,
  );

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final Database database;
  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Listado de Productos',
      home: ProductList(database: database),
    );
  }
}

class ProductList extends StatefulWidget {
  final Database database;
  const ProductList({Key? key, required this.database}) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  List<Map<String, dynamic>> productos = [];

  @override
  void initState() {
    super.initState();
    _obtenerProductos();
  }

  // Método para consultar todos los productos de la tabla
  Future<void> _obtenerProductos() async {
    final List<Map<String, dynamic>> listaProductos = await widget.database
        .query('productos');
    setState(() {
      productos = listaProductos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Listado de Productos')),
      body: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(productos[index]['name']));
        },
      ),
    );
  }
}
