import React, { useState } from 'react'

const API_BASE = import.meta.env.VITE_API_BASE || '/api'

export default function TodoForm({ onAdd }){
  const [title, setTitle] = useState('')
  const [dueDate, setDueDate] = useState('')
  const [categories, setCategories] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async (e) =>{
    e.preventDefault()
    if(!title.trim()) return
    setSubmitting(true)
    const payload = {
      title: title.trim(),
      due_date: dueDate || null,
      categories: categories ? categories.split(',').map(s => s.trim()).filter(Boolean) : []
    }
    try{
      const res = await fetch(`${API_BASE}/todos`, { method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(payload) })
      if(res.ok){
        const item = await res.json()
        onAdd(item)
        setTitle('')
        setDueDate('')
        setCategories('')
      }else{
        console.error('Failed to add', await res.text())
      }
    }catch(err){ console.error(err) }
    setSubmitting(false)
  }

  return (
    <form className="todo-form" onSubmit={handleSubmit}>
      <div className="row">
        <input value={title} onChange={e => setTitle(e.target.value)} placeholder="What needs to be done?" />
        <button type="submit" disabled={submitting}>Add</button>
      </div>
      <div className="row small">
        <input type="date" value={dueDate} onChange={e=>setDueDate(e.target.value)} />
        <input value={categories} onChange={e=>setCategories(e.target.value)} placeholder="categories (comma separated)" />
      </div>
    </form>
  )
}
