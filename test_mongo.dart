import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  print('Testing connection...');
  try {
    var db = await Db.create('mongodb://YOUR_DB_USER:YOUR_DB_PASSWORD@ac-gfrmfwn-shard-00-00.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-01.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-02.3f9wxcf.mongodb.net:27017/ascent_db?authSource=admin&replicaSet=atlas-co8mro-shard-0&tls=true');
    await db.open();
    print('Connected successfully!');
    await db.close();
  } catch (e) {
    print('Connection failed: $e');
  }
}
