C'est parti. Voici le guide **ultime**, structuré et **pédagogique**. Pour chaque fichier, je t'explique exactement **pourquoi** il existe et **ce qu'il fait** dans l'architecture Android moderne.

L'ordre suit la logique de construction : **Configuration ➔ Données ➔ Logique ➔ Interface**.

---

### 🛠️ Étape 1 : Configuration du Projet

*C'est la fondation. On définit les outils et les permissions.*

#### 1. `build.gradle.kts (Module : app)`

**À quoi ça sert ?**
C'est la liste des ingrédients de ton application. On y ajoute les librairies externes :

* **Room** : Pour gérer la base de données SQL facilement.
* **Retrofit** : Pour faire les appels réseau (API).
* **Navigation & ViewModel** : Les composants d'architecture Google.

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.devtools.ksp") // Essentiel pour que Room génère son code
}

android {
    namespace = "iutlr.butinfo3.devbdmob.mycampustasks"
    compileSdk = 34

    defaultConfig {
        applicationId = "iutlr.butinfo3.devbdmob.mycampustasks"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
}

dependencies {
    // Interface Utilisateur (Jetpack Compose)
    implementation(platform("androidx.compose:compose-bom:2023.08.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    
    // Base de données (Room)
    val room_version = "2.6.1"
    implementation("androidx.room:room-runtime:$room_version")
    implementation("androidx.room:room-ktx:$room_version") // Extensions Kotlin pour Room
    ksp("androidx.room:room-compiler:$room_version")       // Le compilateur

    // Réseau (Retrofit)
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-gson:2.9.0") // Pour convertir JSON <-> Objets

    // Architecture
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    implementation("androidx.navigation:navigation-compose:2.7.5")
}

```

#### 2. `AndroidManifest.xml`

**À quoi ça sert ?**
C'est la carte d'identité de l'app.

1. On demande la permission d'utiliser Internet (`INTERNET`).
2. On déclare notre classe `Application` personnalisée (`.MyCampusTasksApplication`) qui sera créée à l'étape 8.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:name=".MyCampusTasksApplication"
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/Theme.MyCampusTasks"
        tools:targetApi="31">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.MyCampusTasks">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>

```

---

### 📦 Étape 2 : Le Modèle de Données (Base de données locale)

*On définit "Qu'est-ce qu'une tâche ?" et "Comment on la stocke ?".*

#### 3. `model/Task.kt`

**À quoi ça sert ?**
C'est l'**Entité**. L'annotation `@Entity` dit à Room de créer une table SQL nommée "task" avec ces colonnes. C'est l'objet métier principal.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

@Entity(tableName = "task")
data class Task(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,
    
    val subject: String,
    
    @ColumnInfo(name = "task_place") // Nom personnalisé pour la colonne SQL
    var place: String,
    
    @ColumnInfo(name = "description")
    var description: String? = null,
    
    @ColumnInfo(name = "created_at")
    val createdAt: Date? = Date()
)

```

#### 4. `model/DateTypeConverter.kt`

**À quoi ça sert ?**
Room ne sait stocker que des nombres et du texte. Il ne connaît pas le type `Date`. Ce fichier sert de traducteur :

* `Date` -> `Long` (pour écrire en base)
* `Long` -> `Date` (pour lire depuis la base).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import androidx.room.TypeConverter
import java.util.Date

class DateTypeConverter {
    @TypeConverter
    fun toDate(timestamp: Long?): Date? = timestamp?.let { Date(it) }

    @TypeConverter
    fun toLong(date: Date?): Long? = date?.time
}

```

#### 5. `model/TaskDao.kt`

**À quoi ça sert ?**
DAO = **Data Access Object**. C'est une interface qui contient les méthodes pour interagir avec la base de données (INSERT, DELETE, SELECT).
L'utilisation de `Flow` permet à l'interface de se mettre à jour automatiquement quand les données changent.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM task ORDER BY subject ASC")
    fun getAllTasks(): Flow<List<Task>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(task: Task) // suspend car opération longue

    @Delete
    suspend fun delete(task: Task)
}

```

#### 6. `model/TaskDatabase.kt`

**À quoi ça sert ?**
C'est le point d'accès principal à la base de données.
Elle utilise le pattern **Singleton** (`INSTANCE`) pour s'assurer qu'on n'ouvre pas plusieurs connexions à la base en même temps (ce qui serait mauvais pour la mémoire).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

@Database(entities = [Task::class], version = 1, exportSchema = false)
@TypeConverters(DateTypeConverter::class) // On attache le convertisseur ici
abstract class TaskDatabase : RoomDatabase() {
    abstract fun taskDao(): TaskDao

    companion object {
        @Volatile
        private var INSTANCE: TaskDatabase? = null

        fun getDatabase(context: Context): TaskDatabase {
            return INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context, TaskDatabase::class.java, "task_database")
                    .fallbackToDestructiveMigration() // Réinitialise la DB si on change le schéma
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}

```

---

### 🌐 Étape 3 : Le Modèle Réseau (API)

*Pour communiquer avec le serveur.*

#### 7. `model/api/TaskDto.kt`

**À quoi ça sert ?**
DTO = **Data Transfer Object**. C'est la représentation exacte du JSON renvoyé par l'API. On sépare le DTO (réseau) de l'Entity (base locale) pour plus de propreté.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model.api

import iutlr.butinfo3.devbdmob.mycampustasks.model.Task

data class TaskDto(
    val id: Int,
    val subject: String,
    val place: String,
    val description: String?,
    val owner: String
) {
    // Convertit le format Réseau vers le format Local
    fun toTask() = Task(id, subject, place, description)
}

data class CreateTaskDto(
    val subject: String,
    val place: String,
    val description: String?,
    val owner: String
)

```

#### 8. `model/api/TaskApiService.kt`

**À quoi ça sert ?**
C'est l'interface **Retrofit**. Elle définit les URLs de l'API (`/tasks`) et les méthodes HTTP (GET, POST, DELETE).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model.api

import retrofit2.http.*

interface TaskApiService {
    @GET("tasks")
    suspend fun getTasks(): List<TaskDto>

    @POST("tasks")
    suspend fun createTask(@Body task: CreateTaskDto): TaskDto

    @DELETE("tasks/{id}")
    suspend fun deleteTask(@Path("id") id: Int)
}

```

#### 9. `model/api/RetrofitClient.kt`

**À quoi ça sert ?**
C'est la configuration du client HTTP. C'est ici qu'on indique l'URL de base du serveur et qu'on ajoute le convertisseur JSON (Gson).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model.api

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object RetrofitClient {
    private const val BASE_URL = "https://mycampustasks.k8s.iut-larochelle.fr/api/"

    val instance: TaskApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TaskApiService::class.java)
    }
}

```

---

### 🔄 Étape 4 : Le Repository (L'intermédiaire)

*Il fait le lien entre les données (Model) et la logique (ViewModel).*

#### 10. `model/TasksRepository.kt`

**À quoi ça sert ?**
C'est une **Interface**. Elle permet de définir *quelles* actions sont possibles sans dire *comment* (via API ou via Base locale). Ça rend le code modulaire.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import kotlinx.coroutines.flow.Flow

interface TasksRepository {
    fun getTasks(): Flow<List<Task>>
    suspend fun insertTask(task: Task)
    suspend fun deleteTask(task: Task)
}

```

#### 11. `model/OfflineTasksRepository.kt`

**À quoi ça sert ?**
C'est l'implémentation concrète pour le mode **Offline**. Elle redirige les demandes vers le `TaskDao` (Room).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.model

import kotlinx.coroutines.flow.Flow

class OfflineTasksRepository(private val taskDao: TaskDao) : TasksRepository {
    override fun getTasks(): Flow<List<Task>> = taskDao.getAllTasks()
    override suspend fun insertTask(task: Task) = taskDao.insert(task)
    override suspend fun deleteTask(task: Task) = taskDao.delete(task)
}

```

---

### 🧠 Étape 5 : Le ViewModel (Le Cerveau)

*Il gère l'état de l'écran et survit aux rotations.*

#### 12. `viewmodel/TaskViewModel.kt`

**À quoi ça sert ?**

1. Il stocke les données (`StateFlow`) : le texte saisi par l'utilisateur.
2. Il expose la liste des tâches.
3. Il lance les coroutines (`viewModelScope.launch`) pour exécuter les actions en arrière-plan sans bloquer l'interface.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import iutlr.butinfo3.devbdmob.mycampustasks.model.Task
import iutlr.butinfo3.devbdmob.mycampustasks.model.TasksRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class TaskViewModel(private val tasksRepository: TasksRepository) : ViewModel() {

    // État du champ "Sujet"
    private val _subject = MutableStateFlow("")
    val subject: StateFlow<String> = _subject.asStateFlow()

    // État du champ "Lieu"
    private val _place = MutableStateFlow("")
    val place: StateFlow<String> = _place.asStateFlow()

    // Liste des tâches (Flux continu depuis la DB)
    val tasks = tasksRepository.getTasks()

    // Méthodes appelées par l'UI pour modifier l'état
    fun onSubjectChange(newSubject: String) { _subject.value = newSubject }
    fun onPlaceChange(newPlace: String) { _place.value = newPlace }

    // Ajout d'une tâche
    fun addTask() {
        if (_subject.value.isNotEmpty() && _place.value.isNotEmpty()) {
            viewModelScope.launch {
                val newTask = Task(subject = _subject.value, place = _place.value)
                tasksRepository.insertTask(newTask)
                // Remise à zéro des champs
                _subject.value = ""
                _place.value = ""
            }
        }
    }

    fun removeTask(task: Task) {
        viewModelScope.launch { tasksRepository.deleteTask(task) }
    }
}

```

#### 13. `viewmodel/TaskViewModelFactory.kt`

**À quoi ça sert ?**
Par défaut, Android ne sait créer que des ViewModels vides. Comme notre `TaskViewModel` a besoin d'un paramètre (`repository`), on doit créer cette Factory pour expliquer à Android comment le construire (Injection de dépendance manuelle).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import iutlr.butinfo3.devbdmob.mycampustasks.model.TasksRepository

class TaskViewModelFactory(private val repository: TasksRepository) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(TaskViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return TaskViewModel(repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}

```

---

### 🎨 Étape 6 : L'Interface (Les Composables)

*Les briques visuelles.*

#### 14. `ui/task/TaskItem.kt`

**À quoi ça sert ?**
C'est un composant réutilisable qui dessine **une seule ligne** de la liste : une carte avec le titre, le lieu et une icône poubelle. C'est un composant "stateless" (il ne gère pas d'état lui-même, il reçoit des ordres).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.ui.task

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import iutlr.butinfo3.devbdmob.mycampustasks.model.Task

@Composable
fun TaskItem(task: Task, onDelete: () -> Unit) {
    Card(modifier = Modifier.fillMaxWidth().padding(8.dp)) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = task.subject, style = MaterialTheme.typography.titleMedium)
                Text(text = task.place, style = MaterialTheme.typography.bodyMedium)
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Default.Delete, contentDescription = "Supprimer")
            }
        }
    }
}

```

#### 15. `ui/task/TaskInput.kt`

**À quoi ça sert ?**
C'est le formulaire de saisie. Il reçoit l'état (`subject`, `place`) et renvoie les événements (`onSubjectChange`, `onAddClick`). C'est le principe du **State Hoisting** (remontée d'état).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.ui.task

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun TaskInput(
    subject: String,
    place: String,
    onSubjectChange: (String) -> Unit,
    onPlaceChange: (String) -> Unit,
    onAddClick: () -> Unit
) {
    Column(modifier = Modifier.padding(16.dp)) {
        OutlinedTextField(
            value = subject,
            onValueChange = onSubjectChange,
            label = { Text("Sujet") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))
        OutlinedTextField(
            value = place,
            onValueChange = onPlaceChange,
            label = { Text("Lieu") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))
        Button(
            onClick = onAddClick,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Ajouter Tâche")
        }
    }
}

```

#### 16. `ui/home/HomeScreen.kt`

**À quoi ça sert ?**
C'est l'écran principal.

1. Il instancie le ViewModel.
2. Il "écoute" les données (`collectAsState`).
3. Il assemble le formulaire (`TaskInput`) et la liste (`LazyColumn`) dans un `Scaffold`.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks.ui.home

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import iutlr.butinfo3.devbdmob.mycampustasks.MyCampusTasksApplication
import iutlr.butinfo3.devbdmob.mycampustasks.ui.task.TaskInput
import iutlr.butinfo3.devbdmob.mycampustasks.ui.task.TaskItem
import iutlr.butinfo3.devbdmob.mycampustasks.viewmodel.TaskViewModel
import iutlr.butinfo3.devbdmob.mycampustasks.viewmodel.TaskViewModelFactory

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    modifier: Modifier = Modifier,
    // Création du ViewModel avec injection du Repository depuis l'Application
    viewModel: TaskViewModel = viewModel(
        factory = TaskViewModelFactory(
            (LocalContext.current.applicationContext as MyCampusTasksApplication).tasksRepository
        )
    )
) {
    // Observation des flux de données (StateFlow -> State)
    val tasks by viewModel.tasks.collectAsState(initial = emptyList())
    val subject by viewModel.subject.collectAsState()
    val place by viewModel.place.collectAsState()

    Scaffold(
        topBar = { CenterAlignedTopAppBar(title = { Text("MyCampusTasks") }) }
    ) { innerPadding ->
        Column(modifier = modifier.padding(innerPadding)) {
            // Zone de saisie
            TaskInput(
                subject = subject,
                place = place,
                onSubjectChange = { viewModel.onSubjectChange(it) },
                onPlaceChange = { viewModel.onPlaceChange(it) },
                onAddClick = { viewModel.addTask() }
            )
            
            Divider()

            // Liste performante
            LazyColumn {
                items(tasks) { task ->
                    TaskItem(task = task, onDelete = { viewModel.removeTask(task) })
                }
            }
        }
    }
}

```

---

### 🚀 Étape 7 : L'Application et le Démarrage

*C'est là que tout s'assemble.*

#### 17. `MyCampusTasksApplication.kt`

**À quoi ça sert ?**
C'est un **Singleton** qui représente l'application entière.
On y crée la base de données et le Repository **une seule fois** (pattern Lazy) pour qu'ils soient disponibles partout via `applicationContext`.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks

import android.app.Application
import iutlr.butinfo3.devbdmob.mycampustasks.model.OfflineTasksRepository
import iutlr.butinfo3.devbdmob.mycampustasks.model.TaskDatabase

class MyCampusTasksApplication : Application() {
    // Lazy : créé seulement quand on en a besoin pour la 1ère fois
    val database by lazy { TaskDatabase.getDatabase(this) }
    val tasksRepository by lazy { OfflineTasksRepository(database.taskDao()) }
}

```

#### 18. `MyCampusTasksApp.kt`

**À quoi ça sert ?**
C'est le composable racine. Pour l'instant il affiche juste `HomeScreen`, mais plus tard c'est ici qu'on mettrait la Navigation (NavHost).

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks

import androidx.compose.runtime.Composable
import iutlr.butinfo3.devbdmob.mycampustasks.ui.home.HomeScreen

@Composable
fun MyCampusTasksApp() {
    HomeScreen()
}

```

#### 19. `MainActivity.kt`

**À quoi ça sert ?**
C'est le point d'entrée Android (`Activity`). C'est ici que l'application démarre et qu'on définit le contenu de l'écran avec `setContent`.

```kotlin
package iutlr.butinfo3.devbdmob.mycampustasks

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import iutlr.butinfo3.devbdmob.mycampustasks.ui.theme.MyCampusTasksTheme // Assure-toi d'avoir le thème généré

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            // Application du thème global
            MyCampusTasksTheme {
                MyCampusTasksApp()
            }
        }
    }
}

```