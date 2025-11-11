import React from 'react'

export default function TodoList({ todos = [], onDelete }){
  if(!todos.length) return <p className="empty">No to-dos yet.</p>

  return (
    <ul className="todo-list">
      {todos.map(item => (
        <li key={item.id} className="todo-item">
          <div className="meta">
            <div className="title">{item.title}</div>
            <div className="timestamp">{item.timestamp}</div>
          </div>
          <div className="actions">
            <button className="delete" onClick={()=>onDelete(item.id)}>Delete</button>
          </div>
        </li>
      ))}
    </ul>
  )
}
