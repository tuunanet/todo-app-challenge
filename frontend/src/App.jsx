import React, { useEffect, useState } from 'react'
import TodoForm from './components/TodoForm'
import TodoList from './components/TodoList'

const API_BASE = import.meta.env.VITE_API_BASE || '/api'

export default function App(){
  const [todos, setTodos] = useState([])
  const [loading, setLoading] = useState(false)

  const fetchTodos = async () => {
    setLoading(true)
    try{
      const res = await fetch(`${API_BASE}/todos`)
      if(res.ok){
        const data = await res.json()
        setTodos(data)
      }
    }catch(e){
      console.error(e)
    }finally{ setLoading(false) }
  }

  useEffect(()=>{ fetchTodos() }, [])

  const handleAdd = (item) => {
    // prepend new item
    setTodos(prev => [item, ...prev])
  }

  const handleDelete = async (id) => {
    try{
      const res = await fetch(`${API_BASE}/todos/${id}`, { method: 'DELETE' })
      if(res.ok){
        setTodos(prev => prev.filter(t => t.id !== id))
      }
    }catch(e){ console.error(e) }
  }

  return (
    <div className="container">
      <header>
        <h1>To-Do</h1>
        <p className="subtitle">Simple, responsive To-Do app (scaffold)</p>
      </header>
      <main>
        <TodoForm onAdd={handleAdd} />
        {loading ? <p>Loading...</p> : <TodoList todos={todos} onDelete={handleDelete} />}
      </main>
      <footer>
        <small>Scaffolded for Azure deployment</small>
      </footer>
    </div>
  )
}
